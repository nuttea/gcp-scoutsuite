FROM python:3.8

LABEL maintainer="Jason Ross <jason.ross@nccgroup.com>"

# Copy helper scripts to container
ADD bin /root/bin

# Install required software
RUN ["/bin/bash", "-c", "/root/bin/container-install-prereqs.sh"]

# Install AWS CLI
#RUN ["/bin/bash", "-c", "/root/bin/container-install-aws2.sh"]

# Install Azure CLI
#RUN ["/bin/bash", "-c", "/root/bin/container-install-azure.sh"]

# Install gCloud SDK
RUN ["/bin/bash", "-c", "/root/bin/container-install-gcp.sh"]

# Install ScoutSuite
RUN ["/bin/bash", "-c", "/root/bin/container-install-scoutsuite.sh"]

# Set a nice message
RUN ["/bin/bash", "-c", "/root/bin/container-set-init.sh"]

# Remove scripts
RUN ["rm", "-rf", "/root/bin"]

# Command
CMD ["/bin/bash"]
