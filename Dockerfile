FROM centos:7

COPY ./scif_app_recipes/*  /opt/

RUN echo "Install basic development tools" && \
    yum -y groupinstall "Development Tools" && \
    yum -y update && yum -y install wget curl && \
    echo "Install python2.7 setuptools and pip" && \
    yum -y install python-setuptools && \
    easy_install pip && \
    echo "Installing SCI-F" && \
    pip install scif ipython && \
    echo "Installing plasmidID app" && \
    scif install /opt/pikavirus_v1.0_centos7.scif

# ENV find /scif/apps -maxdepth 2 -name "bin" | while read in; do echo "PATH=\${PATH}:$in";done | tr '\n' ' '
ENV PATH=${PATH}:/scif/apps/bedtools/bin
ENV PATH=${PATH}:/scif/apps/bedtools/bin
ENV PATH=${PATH}:/scif/apps/fastqc/bin
ENV PATH=${PATH}:/scif/apps/ncbiblast/bin
ENV PATH=${PATH}:/scif/apps/quast/bin
ENV PATH=${PATH}:/scif/apps/R/bin
ENV PATH=${PATH}:/scif/apps/samtools/bin
ENV PATH=${PATH}:/scif/apps/spades/bin
ENV PATH=${PATH}:/scif/apps/trimmomatic/bin


ENTRYPOINT ["/opt/docker-entrypoint.sh"]
CMD ["samtools"]
