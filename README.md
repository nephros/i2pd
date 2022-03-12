# i2pd for Sailfish OS

The Invisible Internet Project (I2P) is a fully encrypted private network layer
that has been developed with privacy and security by design in order to provide
protection for your activity, location and your identity.

i2pd (I2P Daemon) is a full-featured C++ implementation of I2P client.

More information:

  - [Invisible Internet Project](https://geti2p.net/en/about/intro)
  - [i2pd Documentation](https://i2pd.readthedocs.io/en/latest/)
  - [i2pd User Guide](https://i2pd.readthedocs.io/en/latest/user-guide/)
  - [i2pd Source Code](https://github.com/PurpleI2P/i2pd/)


## Configuration notes for SailfishOS

The daemon comes with a systemd unit, which can be started by `systemctl start i2pd`.

The pre-configured config has the following configured:
  - HTTP proxy at port 4444
  - SOCKS proxy at port 4447
  - web console at http://127.0.0.1:7070, authentication information can be seen in the config file.
  - all other services (SAM, BOB...) are disabled, so re-enable them if you need them
  - NO logging enabled
  - joined to the 'sailfishos' router family, see below

The config and datadir are set to `/home/.system/var/lib/i2pd`, so they are
protected by device encryption, if that is enabled.

Be sure to familiarise yourself with the
[Documentation](https://i2pd.readthedocs.io/en/latest/user-guide/) on how to
change the config.

Things you might want to change:
  - for debugging, set the log level to something other than 'none', or set a log file. 
  - user/password settings for the web console
  - the family configuration, see below
  - allowing transient tunnels (which is ON and shared bandwidth set to 20%).
    If you pay for data, you'll probably want to turn this off. You can also do
    that per-session in the web console.

## Browser/Proxy setup

In order to browse the I2P web, you need to access it through one of the proxy options.

The author does this through
[Privoxy](https://gitlab.com/nephros/harbour-privoxy/-/blob/master/README.md)
by adding the following to the Privoxy config:

       forward-socks5    *.i2p  127.0.0.1:4447 .
       forwarded-connect-retries  5

If you do not want to use privoxy, the following applies:

 - Global Proxy can be set up under Settings -> Mobile Network -> Advanced. Set it to `http://127.0.0.1` and port `4444`
 - Proxy settings for the browser can be set up in `about:config` or through a `user.js` file:

     ```
     network.proxy.http = 127.0.0.1
     network.proxy.http_port = 4444
     network.proxy.type = 1
     network.proxy.socks_remote_dns = true
     ```

You will have to find a way to resolve .i2p addresses, as a proxy does not do that.
Configuring DNS is beyond the scope of this README though.

### Family

The pre-configured config installs a family certificate and configuration entry
for a router family called 'sailfishos'. This is mostly just for fun, but if
you're concerned about privacy or security due to this be sure to disable the
`family` setting in the config.

Also, at the moment, certificate and key are:
  - created at build time, i.e. will change with each package version
  - "widely" available because of this, and may be misused by bad actors

