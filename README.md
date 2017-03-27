Supported tags and respective `Dockerfile` links
================================================

  * [`latest` (Dockerfile)](https://github.com/wernight/docker-dante/blob/master/Dockerfile) [![](https://images.microbadger.com/badges/image/wernight/dante.svg)](https://microbadger.com/images/wernight/dante "Get your own image badge on microbadger.com")

**WORK IN PROGRESS**


What is Dante
-------------

[**Dante**](http://www.inet.no/dante/index.html) consists of a SOCKS server and a SOCKS client, implementing RFC 1928 and related standards. It can in most cases be made transparent to clients, providing functionality somewhat similar to what could be described as a non-transparent Layer 4 router. For customers interested in controlling and monitoring access in or out of their network, the Dante SOCKS server can provide several benefits, including security and TCP/IP termination (no direct contact between hosts inside and outside of the customer network), resource control (bandwidth, sessions), logging (host information, data transferred), and authentication.


Usage example
-------------

    $ docker run -d -p 1080:1080 wernight/dante

Change its configuration by mounting a custom `/etc/sockd.conf`
(see [sample config files](https://www.inet.no/dante/doc/1.4.x/config/server.html)).


### Client-side set up

Set your browser or application to use SOCKS proxy `localhost` on port 1080,
or set to use PAC script like:

    function FindProxyForURL(url, host) {
      return "SOCKS localhost:1080";
    }


Feedbacks
---------

Suggestions are welcome on our [GitHub issue tracker](https://github.com/wernight/docker-dante/issues).
