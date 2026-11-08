
FROM docker.io/library/rockylinux:9 AS rocky9_podman_wsl

# Allow container image docs
RUN sed -i '/^tsflags=nodocs/d' /etc/dnf/dnf.conf

# Install packages
RUN dnf -y install \
    # Required for podman/buildah \
        systemd \
        sudo \
        podman \
        buildah \
        passt \
    # Additional packages \
        vim \
        tmux \
        git \
        && \
    dnf clean all && \
    rm -rf /var/cache/dnf
 
# User with passwordless sudo + subordinate IDs for rootless podman
RUN useradd -m -G wheel -s /bin/bash "dan" && \
    echo "dan ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/dan && \
    chmod 0440 "/etc/sudoers.d/dan" && \
    { grep -q "^dan:" /etc/subuid || echo "dan:100000:65536" >> /etc/subuid; } && \
    { grep -q "^dan:" /etc/subgid || echo "dan:100000:65536" >> /etc/subgid; }
 
# Rootless podman needs newuidmap/newgidmap to be setuid or have file caps.
# Tar export/import drops file caps (xattrs) but keeps the setuid bit.
RUN chmod u+s /usr/bin/newuidmap /usr/bin/newgidmap
 
# WSL config: systemd on, default user, and make / a shared mount at boot
RUN printf '%s\n' \
      '[boot]' \
      'systemd=true' \
      'command = "mount --make-rshared /"' \
      '' \
      '[user]' \
      'default=dan' \
      '' \
      '[network]' \
      'hostname=rocky9' \
      '' \
      '[interop]' \
      'appendWindowsPath=true' \
      > /etc/wsl.conf
 
# Fresh machine-id generated on first boot of each imported copy
RUN truncate -s 0 /etc/machine-id && rm -f /var/lib/dbus/machine-id
