FROM scratch

ADD sbin/apk.static /sbin/
ADD etc/apk/repositories /etc/apk/
RUN [ "/sbin/apk.static", "--allow-untrusted", "-U", \
      "add", "--initdb", \
      "alpine-keys" ]

RUN ["/sbin/apk.static", "add", "--update", "alpine-base", "xvfb", "wine"]
ADD winetricks.sh /
RUN chmod +x winetricks.sh && mv winetricks.sh /usr/bin/winetricks
								    
ENV WINEARCH win32
ENV DISPLAY :0

# Default execute the entrypoint
CMD ["/bin/sh"]
