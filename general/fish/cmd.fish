function osc52-copy
    set -l data (echo -n $argv | base64 | tr -d '\n')
    set -l esc "\033]52;c;$data\a"
    if test -n "$TMUX"
        printf "\033Ptmux;\033$esc\033\\"
    else
        printf $esc
    end
end

set -gx ALIYUN_REGISTRY crpi-lgqv70s6wfdw4zdl.cn-hangzhou.personal.cr.aliyuncs.com


function docker-aliyun-push
    # The function takes one argument, which is the name of the person to greet
    set -l image $argv[1]
    docker tag $image $ALIYUN_REGISTRY/yuyi_docker_cn/$image
    docker push $ALIYUN_REGISTRY/yuyi_docker_cn/$image
    docker rmi $ALIYUN_REGISTRY/yuyi_docker_cn/$image
end


function docker-aliyun-pull
    # The function takes one argument, which is the name of the person to greet
    set -l image $argv[1]
    docker pull $ALIYUN_REGISTRY/yuyi_docker_cn/$image
    docker tag $ALIYUN_REGISTRY/yuyi_docker_cn/$image $image
    docker rmi $ALIYUN_REGISTRY/yuyi_docker_cn/$image
end
