default:	docker_build

docker_build:
	@docker buildx build \
	--push \
	--platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
	--tag jasiek/latex:buildx-latest \
        --build-arg VCS_REF=`git rev-parse --short HEAD` \
        --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` .

