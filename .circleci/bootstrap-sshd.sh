#!/bin/sh
set -ex

SSH_KEY_PATH=/home/circleci/.ssh/integration-test

# generate an ssh key for use in testing
ssh-keygen -t rsa -b 2048 -N '' -f ${SSH_KEY_PATH}

# install sshpass so we can use a password on the the command line
sudo apt-get -q update
sudo apt-get -q install -y sshpass

# trust the host key for the sshd container
ssh-keyscan localhost >> /home/circleci/.ssh/known_hosts

# install an authorized keys file
sshpass -p root -- ssh root@localhost "mkdir -p /root/.ssh && tee -a /root/.ssh/authorized_keys" < ${SSH_KEY_PATH}.pub

# generate a secondary user for testing with the same SSH key
ssh -i ${SSH_KEY_PATH} root@localhost \
    "adduser -D -s /bin/ash giraffe \
     && passwd -u giraffe \
     && mkdir -p /home/giraffe/.ssh && cp /root/.ssh/authorized_keys /home/giraffe/.ssh/authorized_keys \
     && chown -R giraffe:giraffe /home/giraffe"

# install GNU coreutils, since Giraffe is not fully POSIX compliant
# https://github.com/palantir/giraffe/issues/69
ssh -i ${SSH_KEY_PATH} root@localhost "apk add --update coreutils"

# copy test file creation scripts
scp -i ${SSH_KEY_PATH} ssh/build/system-test-files/exec-creator.sh ssh/build/system-test-files/file-creator.sh  giraffe@localhost:~

# create test files
ssh -i ${SSH_KEY_PATH} giraffe@localhost "./exec-creator.sh exec && ./file-creator.sh file"
