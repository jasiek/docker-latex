# YEAR is a global build arg; stages that use it redeclare ARG YEAR below.
ARG YEAR

FROM debian:bookworm-slim AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends perl \
 && rm -rf /var/lib/apt/lists/*

FROM base AS installer
ARG YEAR
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates wget xz-utils binutils \
 && rm -rf /var/lib/apt/lists/*
RUN mkdir /source
WORKDIR /source
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
RUN tar -zxf install-tl-unx.tar.gz
RUN rm *.gz
ADD texlive.profile /source
RUN cd install-tl-* && ./install-tl -profile ../texlive.profile
ENV PATH="/usr/local/texlive/${YEAR}/bin/x86_64-linux/:/usr/local/texlive/${YEAR}/bin/aarch64-linux/:/usr/local/texlive/${YEAR}/bin/armhf-linux/:${PATH}"
RUN tlmgr init-usertree
RUN tlmgr option autobackup 0
RUN tlmgr update --self --all
RUN luaotfload-tool -fu
RUN tlmgr install moderncv etoolbox xcolor l3packages l3kernel microtype pgf babel-polish censor pbox ifnextok palatino helvetic mathpazo collection-fontsrecommended beamer powerdot letltxmacro latexmk multirow arydshln tokcycle

# Trim files that are not needed to run latexmk from the tree that gets
# copied into the final image (the tlmgr database, package metadata, leftover
# docs/sources, and installer artifacts). Then strip the engine binaries.
RUN set -eux; \
    tldir="$(ls -d /usr/local/texlive/[0-9]*)"; \
    rm -rf "$tldir"/tlpkg/texlive.tlpdb \
           "$tldir"/tlpkg/backups \
           "$tldir"/tlpkg/installer \
           "$tldir"/tlpkg/temp \
           "$tldir"/tlpkg/tlpobj \
           "$tldir"/tlpkg/gpg \
           "$tldir"/texmf-dist/doc \
           "$tldir"/texmf-dist/source \
           "$tldir"/install-tl \
           "$tldir"/install-tl.log \
           "$tldir"/*.html; \
    find "$tldir"/bin -type f -exec strip --strip-unneeded {} + 2>/dev/null || true

FROM base
ARG YEAR
COPY --from=installer /usr/local/texlive /usr/local/texlive
ENV PATH="/usr/local/texlive/${YEAR}/bin/x86_64-linux/:/usr/local/texlive/${YEAR}/bin/aarch64-linux/:/usr/local/texlive/${YEAR}/bin/armhf-linux/:${PATH}"
WORKDIR /source
ENTRYPOINT ["latexmk", "-pdf"]

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/jasiek/docker-latex" \
      org.label-schema.build-date=$BUILD_DATE
