year := $(shell curl https://ctan.gust.org.pl/tex-archive/systems/texlive/tlnet/ | grep TEXLIVE_ | cut -d _ -f 2 | cut -d \" -f 1)
vcs_ref := $(shell git rev-parse --short HEAD)
build_date := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
default:	docker_build

docker_build:
	@docker buildx build \
	--push \
	--platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
	--tag jasiek/latex:latest \
        --build-arg VCS_REF=$(vcs_ref) \
	--build-arg YEAR=$(year) \
	--build-arg BUILD_DATE=$(build_date) .


docker_build_arm64:
	@docker build -t jasiek/latex:latest \
	--platform linux/arm64/v8 \
        --build-arg VCS_REF=$(vcs_ref) \
	--build-arg YEAR=$(year) \
        --build-arg BUILD_DATE=$(build_date) .

docker_build_armv7:
	@docker build -t jasiek/latex:latest \
	--platform linux/arm/v7 \
        --build-arg VCS_REF=$(vcs_ref) \
	--build-arg YEAR=$(year) \
        --build-arg BUILD_DATE=$(build_date) .

docker_build_amd64:
	@docker build -t jasiek/latex:latest \
	--platform linux/amd64 \
        --build-arg VCS_REF=$(vcs_ref) \
	--build-arg YEAR=$(year) \
        --build-arg BUILD_DATE=$(build_date) .

