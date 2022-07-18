#!/bin/bash

while [ -n "$1" ]; do
    case "$1" in
    -p | --profile)
        AWS_PROFILE=$2
        shift
        ;;
    -s | --service)
        AWS_SERVICE=$2
        shift
        ;;
    -c | --cluster)
        AWS_CLUSTER=$2
        shift
        ;;
    --container)
        AWS_CONTAINER=$2
        shift
        ;;
    esac
    shift
done

exec_enable() {
    aws ecs update-service --profile $AWS_PROFILE --cluster $AWS_CLUSTER --service $AWS_SERVICE --enable-execute-command --force-new-deployment >/dev/null
    aws ecs wait services-stable --profile $AWS_PROFILE --cluster $AWS_CLUSTER --services $AWS_SERVICE
}

get_task() {
    AWS_TASK_ARN=$(aws ecs list-tasks --profile $AWS_PROFILE --cluster $AWS_CLUSTER --service-name $AWS_SERVICE | jq -r '.taskArns[0]')
    AWS_TASK_ID=$(basename $AWS_TASK_ARN)
    echo $AWS_TASK_ID
}

execute() {
    aws ecs execute-command --profile $AWS_PROFILE --cluster $AWS_CLUSTER --task $AWS_TASK_ID --container $AWS_CONTAINER --interactive --command "/bin/bash"
}

exec_disable() {
    aws ecs update-service --profile $AWS_PROFILE --cluster $AWS_CLUSTER --service $AWS_SERVICE --disable-execute-command --force-new-deployment >/dev/null
    aws ecs wait services-stable --profile $AWS_PROFILE --cluster $AWS_CLUSTER --services $AWS_SERVICE
}

main() {
    exec_enable && get_task && execute && exec_disable
}

main
