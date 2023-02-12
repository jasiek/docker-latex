FROM ubuntu:latest AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt upgrade -y
RUN apt install -y perl

ARG YEAR

FROM base AS installer
RUN apt install -y wget xz-utils
RUN mkdir /source
WORKDIR /source
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
RUN tar -zxf install-tl-unx.tar.gz
RUN rm *.gz
ADD texlive.profile /source
RUN cd install-tl-* && ./install-tl -profile ../texlive.profile
ENV PATH="/usr/local/texlive/${YEAR}/bin/x86_64-linux/:/usr/local/texlive/${YEAR}/bin/aarch64-linux/:/usr/local/texlive/${YEAR}/bin/armhf-linux/:${PATH}"
RUN tlmgr init-usertree
RUN tlmgr update --self --all
RUN luaotfload-tool -fu
RUN tlmgr install moderncv etoolbox xcolor l3packages l3kernel microtype pgf ms babel-polish censor pbox ifnextok palatino helvetic mathpazo collection-fontsrecommended beamer powerdot letltxmacro latexmk multirow arydshln

FROM base
COPY --from=installer /usr/local/texlive /usr/local/texlive
ENV PATH="/usr/local/texlive/${YEAR}/bin/x86_64-linux/:/usr/local/texlive/${YEAR}/bin/aarch64-linux/:/usr/local/texlive/${YEAR}/bin/armhf-linux/:${PATH}"
RUN apt download latex2rtf
ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y imagemagick
RUN dpkg -i --ignore-depends=texlive-base latex2rtf*
WORKDIR /source
ENTRYPOINT ["latexmk", "-pdf"]

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/jasiek/docker-latex" \
      org.label-schema.build-date=$BUILD_DATE
