# Ktown4u 관련 환경변수 로드
[[ -f ~/.env.ktown4u ]] && source ~/.env.ktown4u

# SSH 접속 alias (TODO: SSH config로 이동 예정)
lias to-zeppelin='ssh -i ~/DocumentsLocal/hminter-VPN/hmmall-keypair.pem ec2-user@172.16.0.175'
