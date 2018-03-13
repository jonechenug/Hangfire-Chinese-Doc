# Hangfire 中文文档
基于官方文档机翻修改，在线访问地址：[点我访问](http://hangfirezh.daocloudapp.com/quick-start.html)
# Docker 支持
运行:
```
docker run --restart always  --name hangfire -d -p 8080:80 daocloud.io/koukouge/hangfirezhdoc
```
浏览器访问 ``http://127.0.0.1:8080/quick-start.html`` 即可查看文档。

删除:
```
docker rm -f hangfire
```
# Hangfire Documentation

[![Documentation Status](https://readthedocs.org/projects/hangfire/badge/?version=latest)](https://readthedocs.org/projects/hangfire/?badge=latest) 

This repository contains [Sphinx-based](http://sphinx-doc.org) documentation for [Hangfire](http://hangfire.io). http://docs.hangfire.io

Contributing
-------------

### The Easy Way

Just click the `Edit on GitHub` button while observing a page with mistakes as shown below. GitHub will guide you to fork the repository. Please don't forget to create a pull request!

![Contributing via Documentation Site](https://raw.githubusercontent.com/HangfireIO/Hangfire-Documentation/master/contributing.png)

Documentation is automatically deployed to the site after each commit. For small changes just propose a pull request. Thanks to [Read the Docs](https://readthedocs.org) service for help!

### The Hard Way

#### Installing Sphinx

[Official installation guide](http://sphinx-doc.org/latest/install.html) describes all steps 
required to run Sphinx on Windows / Linux / Mac OS X.

#### Building

Clone the repository and run the following command:

```
make html
```

After building, generated `*.html` files will be available in the `_build` directory.

License
--------

[![Creative Commons License](https://i.creativecommons.org/l/by/4.0/88x31.png)](http://creativecommons.org/licenses/by/4.0/)

This work is licensed under a <a rel="license" href="http://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.
