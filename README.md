# netos_app

- 这是一款基于flutter的移动端平台框架。

## 设计初衷：
- 并不是所有程序员都能对齐界面元素，而后端凝聚了许多高级程序员；
- 前端和移动端开发的程序员许多缺乏架构思维，导致app不建状，维护成本高，很难跌代。（这让我想到桌面时代，桌面时代的高手在终端，如张小龙的foxmail及ireport）
- 还有前后台的配合问题，目前许多以后端的api主导移动端的对接规范，导致移动端去等接口，那么能不能有一种思路，移动端也可以放出接口api让后端来实现前置接入api呢？这样谁不等谁可以大大提高效率
- app要能支持一个很好的生态，针对各行各业的开发者提供不同层级的编程支持。这点微信做的非常好，它的公共号和小程序，在不同开发层级上支持着全国的开发者。

''' 基于以上选型了flutter，目前及未来，移动端的开发flutter肯定能主导天下，就目前从易开发性和性能来看也是如此。

## 依赖：
- 推荐后台微服务采用gateway2开发，不推荐使用spring boot，当然，netos框架支持任何web容器提供的服务，只是我认为采用网关2开发后端非常简单而且是基于netty的nio并发性更好。

## 架构：
三种开发者角色：
- netos microPortal（微框架）开发者，一般是由netos移动端团队开发，并发布到框架市场，微框架开发者需要具备开发flutter&dart&android&ios技术能力。他们来提供display,style等界面并发布到框架市场，在框架市场微应用和微站的开发者可以看到api
- netos microApp(微应用)开发者，一般是第三方，对于他们是零开发，他们通过界面配置自己的微应用页面，包括为自己的微应用选择框架，为每页选择显示器及主题风格
- netos microSite(微站)开发者，一般是第三方，他们根据微框架公开的api实现这些api。

在此架构之前可以再演进出类似于零开发的企业号功能，每个第三方均可尝试去做，让你的微应用也可像微信一样为你的第三方开放内容api，因此本架构是一个比微信平台更高层级的移动端系统。

![架构图](https://github.com/carocean/gbera_app/blob/master/documents/netos.app-v1.3.png)

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
