#!/bin/bash

if [ "$(id -u)" == "0" ]; then
    if [ "$(stat -c %u /home/jenkins)" != "$(id -u jenkins)" ]; then
        chown -R jenkins /home/jenkins
    fi

    dirs=(
        '/home/jenkins/tools'
        '/home/jenkins/.m2'
        '/home/jenkins/.gradle'
        '/home/jenkins/.coursier'
        '/home/jenkins/.ivy'
        '/home/jenkins/.sbt'
    )
    for d in ${dirs[@]}; do
        if [[ -d $d ]] && [[ "$(stat -c %u $d)" != "$(id -u jenkins)" ]]; then
            chown -R jenkins $d
        fi
    done

    # To enable docker cloud based on docker socket,
    # we need to add jenkins user to the docker group
    if [ -S /var/run/docker.sock ]; then
        DOCKER_SOCKET_OWNER_GROUP_ID=$(stat -c %g /var/run/docker.sock)
        echo "jenkins groups: $(id jenkins -G)"
        getent group $DOCKER_SOCKET_OWNER_GROUP_ID || groupadd -g $DOCKER_SOCKET_OWNER_GROUP_ID docker
        id jenkins -G | grep $DOCKER_SOCKET_OWNER_GROUP_ID || usermod -G "$(id -G jenkins | tr ' ' ','),$DOCKER_SOCKET_OWNER_GROUP_ID" jenkins
        echo "jenkins new groups: $(id jenkins -G)"
    fi
fi

exec gosu jenkins "jenkins-slave" "$@"