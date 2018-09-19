FROM ubuntu:latest AS base
RUN apt-get update
RUN apt-get -y upgrade

FROM base AS installer
RUN apt-get install -y wget xzdec perl
RUN mkdir /source
WORKDIR /source
RUN wget http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
RUN tar -zxf install-tl-unx.tar.gz
RUN rm *.gz
ADD texlive.profile /source
RUN cd install-tl-* && ./install-tl -profile ../texlive.profile
ENV PATH="/usr/local/texlive/2018/bin/x86_64-linux:${PATH}"
RUN tlmgr init-usertree
RUN tlmgr update --self --all
RUN luaotfload-tool -fu
RUN tlmgr install moderncv etoolbox xcolor l3packages l3kernel microtype pgf ms babel-polish censor pbox ifnextok palatino helvetic mathpazo collection-fontsrecommended

FROM base
COPY --from=installer /usr/local/texlive /usr/local/texlive
ENV PATH="/usr/local/texlive/2018/bin/x86_64-linux:${PATH}"
ENTRYPOINT ["pdflatex"]

