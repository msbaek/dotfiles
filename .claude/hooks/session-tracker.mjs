#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const ACTIVE_DIR = process.env.ACTIVE_DIR
  ?? path.join(process.env.HOME ?? '', '.claude', 'dashboard', 'active');

// Read JSON payload from stdin synchronously
// Guard: skip if stdin is a TTY (no pipe) to avoid blocking indefinitely
let raw;
try {
  if (process.stdin.isTTY) process.exit(0);
  raw = JSON.parse(fs.readFileSync(0, 'utf8'));
} catch {
  process.exit(0);
}

const sessionId  = raw.session_id       ?? '';
const hookEvent  = raw.hook_event_name  ?? '';
const cwd        = raw.cwd              ?? '';
const transcript = raw.transcript_path  ?? '';

if (!sessionId) process.exit(0);

const sessionFile = path.join(ACTIVE_DIR, `${sessionId}.json`);

const now = new Date();
const pad = n => String(n).padStart(2, '0');
const timestamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())} `
                + `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;

// Read existing session data
let existing = {};
try {
  existing = JSON.parse(fs.readFileSync(sessionFile, 'utf8'));
} catch { /* new session or parse error */ }

// Fields that fall back to existing values when absent from the current event payload
const resolvedCwd        = cwd        || existing.cwd        || '';
const resolvedTranscript = transcript || existing.transcript || '';
const project = resolvedCwd ? path.basename(resolvedCwd) : (existing.project ?? 'unknown');

// Capture ppid once; reuse on subsequent events (used to detect orphaned sessions)
const ppid = existing.ppid ?? process.ppid;

// Capture TTY once; reuse on subsequent events
let ttyPath = existing.tty ?? '';
if (!ttyPath) {
  try {
    const dev = execFileSync('ps', ['-o', 'tty=', '-p', String(process.ppid)], { encoding: 'utf8' }).trim();
    if (dev && dev !== '??') ttyPath = `/dev/${dev}`;
  } catch { /* ignore */ }
}

let startedAt    = existing.startedAt    ?? timestamp;
let message      = existing.message      ?? '';
let lastResponse = existing.lastResponse ?? '';
let alertAt      = existing.alertAt      ?? '';
let alertEvent   = existing.alertEvent   ?? '';
let subagents    = Array.isArray(existing.subagents) ? existing.subagents : [];
let status;

switch (hookEvent) {
  case 'SessionStart':
    status    = 'waiting';
    message   = 'Session started';
    startedAt = timestamp;
    break;

  case 'UserPromptSubmit': {
    status  = 'working';
    const prompt = raw.prompt ?? '';
    message = prompt ? prompt.slice(0, 100) : 'Processing...';
    break;
  }

  case 'PreToolUse': {
    // PreToolUse means Claude is actively about to use a tool — always 'working'.
    // This also covers the case where UserPromptSubmit didn't fire (hook failure, etc.).
    const cur = existing.status ?? 'working';
    status  = 'working';
    message = cur === 'waiting' ? 'Processing...' : (existing.message ?? 'Processing...');
    break;
  }

  case 'PostToolUse': {
    // Only restore to 'working' from active states; preserve 'waiting' to avoid
    // spurious transitions when a delayed PostToolUse arrives after Stop.
    const cur = existing.status ?? 'working';
    status  = (cur === 'notification' || cur === 'working') ? 'working' : cur;
    message = existing.message ?? 'Processing...';
    break;
  }

  case 'Stop': {
    status       = 'waiting';
    alertAt      = timestamp;
    alertEvent   = 'Stop';
    lastResponse = (raw.last_assistant_message ?? '').slice(0, 200);
    message      = lastResponse ? lastResponse.slice(0, 100) : 'Ready';
    subagents    = [];
    break;
  }

  case 'Notification': {
    // Only elevate to 'notification' when Claude is actively working (permission request).
    // If already waiting, this is a background completion ping — keep 'waiting'.
    const prevStatus = existing.status ?? 'waiting';
    status     = prevStatus === 'working' ? 'notification' : prevStatus;
    alertAt    = timestamp;
    alertEvent = 'Notification';
    if (status === 'notification') {
      message = (raw.message ?? 'Notification').slice(0, 100);
    }
    break;
  }

  case 'SessionEnd':
    try { fs.unlinkSync(sessionFile); } catch { /* already gone */ }
    process.exit(0);
    break;

  case 'SubagentStart': {
    status  = 'working';
    message = existing.message ?? 'Processing...';
    const agentId   = raw.agent_id   ?? '';
    const agentType = raw.agent_type ?? '';
    if (agentId && !subagents.some(s => s.agentId === agentId)) {
      subagents.push({ agentId, agentType, status: 'working', startedAt: timestamp, completedAt: '' });
    }
    break;
  }

  case 'SubagentStop': {
    status    = 'working';
    message   = existing.message ?? 'Processing...';
    const agentId = raw.agent_id ?? '';
    subagents = subagents.filter(s => s.agentId !== agentId);
    break;
  }

  default:
    status = existing.status ?? 'waiting';
}

fs.mkdirSync(ACTIVE_DIR, { recursive: true });

const data = {
  session:      sessionId,
  project,
  cwd:          resolvedCwd,
  status,
  message,
  lastResponse,
  sessionName:  existing.sessionName ?? '',
  transcript:   resolvedTranscript,
  updated:      timestamp,
  startedAt,
  tty:          ttyPath,
  ppid,
  alertAt,
  alertEvent,
  subagents,
};

// Atomic write: write to tmp then rename
const tmp = `${sessionFile}.tmp.${process.pid}`;
try {
  fs.writeFileSync(tmp, JSON.stringify(data, null, 2), 'utf8');
  fs.renameSync(tmp, sessionFile);
} catch (err) {
  try { fs.unlinkSync(tmp); } catch { /* ignore */ }
  throw err;
}
