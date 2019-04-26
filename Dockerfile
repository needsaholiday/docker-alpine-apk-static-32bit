FROM scratch

ADD sbin/apk.static /sbin/
ADD etc/apk/repositories /etc/apk/
RUN [ "/sbin/apk.static", "--allow-untrusted", "-U", \
      "add", "--initdb", \
      "alpine-keys" ]

RUN ["/sbin/apk.static", "add", "--update", "alpine-base", "xvfb", "wine", "wget"]
RUN wget http://winetricks.org/winetricks && chmod +x winetricks && mv winetricks /usr/bin/winetricks
								    
ENV WINEARCH win32
ENV DISPLAY :0

# Default execute the entrypoint
CMD ["/bin/sh"]
