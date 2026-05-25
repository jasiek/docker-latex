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
# scheme-basic provides only the pdflatex core; install the commonly-used
# LaTeX/font collections plus the specific packages our documents need.
# moderncv icons come from marvosym, so fontawesome/academicons are omitted;
# documents must select them with \moderncvicons{marvosym}.
RUN tlmgr install \
      collection-latexrecommended \
      collection-fontsrecommended \
      latexmk \
      moderncv tweaklist marvosym censor \
      beamer powerdot \
      multirow arydshln tokcycle pbox ifnextok letltxmacro \
      babel-polish hyphen-polish hyphen-english \
      geometry hyperref fancyhdr psnfss \
      palatino helvetic mathpazo lm ec \
      etoolbox xcolor microtype iftex l3packages l3kernel

# Trim files that are not needed to run latexmk from the tree that gets
# copied into the final image: the tlmgr database, package metadata, leftover
# docs/sources, installer artifacts, and the non-pdflatex engines (xetex,
# luatex, metapost, context) along with their format caches. Then strip the
# remaining binaries.
RUN set -eux; \
    tldir="$(ls -d /usr/local/texlive/[0-9]*)"; \
    arch="$(ls "$tldir"/bin)"; \
    for b in luatex luahbtex luajittex lualatex dvilualatex texlua texluac \
             xetex xelatex mpost dvitomp mptopdf context mtxrun luatools \
             mtxrunjit contextjit texexec texmfstart; do \
      rm -f "$tldir/bin/$arch/$b"; \
    done; \
    rm -rf "$tldir"/texmf-var/web2c/luatex \
           "$tldir"/texmf-var/web2c/luahbtex \
           "$tldir"/texmf-var/web2c/xetex \
           "$tldir"/tlpkg/texlive.tlpdb \
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
