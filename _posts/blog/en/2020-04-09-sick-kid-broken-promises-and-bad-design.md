---
layout: post
title: Sick kid, broken promises and bad design decisions.
excerpt: How nullable feature of C#8 led me into false safety.
categories: blog
comments: true
lang: en
author: aensidhe_2018
tags:
  - nullability
  - csharp
---

So, I'm on sick leave caring for my daughter. But she's sleeping, so I have some time to play with my very small service: one query to mysql database, format results to CSV, that's it. And it works on my machine. But it fails in cloud, we're getting 500 on endpoint with CSV and, most interesting, we don't have logs at all.

That service is a test bed to some middlewares and formatters that I'm going to promote for use across the company. So, now I'm on a journey, on an adventure: how to find out what's going on in Fargate container, without any logs and abilities to attach my remote debugger. To make things more interesting, I built that application as self-contained, ready-to-run .net core 3.1 application.

Fortunately, problem was easy to replicate in local docker container. No logs, 500, same as in cloud. We're using rider to develop .net applications. Unfortunately, Rider (at the moment of writing) can't debug ready-to-run applications. It can debug apps in docker, though. Ok, let's fallback to VS2019: fortunately it can debug ready-to-run application. One of devs from Jetbrains team said that they will try to ship debug of ready-to-run applications in release after 2020.1. But no promises were made and that's understandable. Still, we're waiting for this feature.

VS2019 has an ability to attach debugger to a process inside of container. Probably, even remote ones, I've never tested it yet. I'm using `FROM mcr.microsoft.com/dotnet/core/runtime-deps:3.1.3-buster-slim` as base image. It doesn't have curl or wget in there, so you need to install one of those by yourself to make that remote debugging work. And yes, VS2019 can debug ready-to-run applications. And we're getting this exception in VS2019:

{% highlight text %}
MySql.Data.MySqlClient.MySqlException (0x80004005): SSL Authentication Error
 ---> System.Security.Authentication.AuthenticationException: Authentication failed, see inner exception.
 ---> Interop+OpenSsl+SslException: SSL Handshake failed with OpenSSL error - SSL_ERROR_SSL.
 ---> Interop+Crypto+OpenSslCryptographicException: error:1425F102:SSL routines:ssl_choose_client_version:unsupported protocol
   --- End of inner exception stack trace ---
   at Interop.OpenSsl.DoSslHandshake(SafeSslHandle context, Byte[] recvBuf, Int32 recvOffset, Int32 recvCount, Byte[]& sendBuf, Int32& sendCount)
   at System.Net.Security.SslStreamPal.HandshakeInternal(SafeFreeCredentials credential, SafeDeleteContext& context, ArraySegment`1 inputBuffer, Byte[]& outputBuffer, SslAuthenticationOptions sslAuthenticationOptions)
   --- End of inner exception stack trace ---
   at System.Net.Security.SslStream.StartSendAuthResetSignal(ProtocolToken message, AsyncProtocolRequest asyncRequest, ExceptionDispatchInfo exception)
   at System.Net.Security.SslStream.CheckCompletionBeforeNextReceive(ProtocolToken message, AsyncProtocolRequest asyncRequest)
   at System.Net.Security.SslStream.StartSendBlob(Byte[] incoming, Int32 count, AsyncProtocolRequest asyncRequest)
   at System.Net.Security.SslStream.ProcessReceivedBlob(Byte[] buffer, Int32 count, AsyncProtocolRequest asyncRequest)
   at System.Net.Security.SslStream.PartialFrameCallback(AsyncProtocolRequest asyncRequest)
--- End of stack trace from previous location where exception was thrown ---
   at System.Net.Security.SslStream.EndProcessAuthentication(IAsyncResult result)
   at System.Threading.Tasks.TaskFactory`1.FromAsyncCoreLogic(IAsyncResult iar, Func`2 endFunction, Action`1 endAction, Task`1 promise, Boolean requiresSynchronization)
--- End of stack trace from previous location where exception was thrown ---
   at MySqlConnector.Core.ServerSession.InitSslAsync(ProtocolCapabilities serverCapabilities, ConnectionSettings cs, SslProtocols sslProtocols, IOBehavior ioBehavior, CancellationToken cancellationToken) in C:\projects\mysqlconnector\src\MySqlConnector\Core\ServerSession.cs:line 1270
   at MySqlConnector.Core.ServerSession.InitSslAsync(ProtocolCapabilities serverCapabilities, ConnectionSettings cs, SslProtocols sslProtocols, IOBehavior ioBehavior, CancellationToken cancellationToken) in C:\projects\mysqlconnector\src\MySqlConnector\Core\ServerSession.cs:line 1297
   at MySqlConnector.Core.ServerSession.ConnectAsync(ConnectionSettings cs, Int32 startTickCount, ILoadBalancer loadBalancer, IOBehavior ioBehavior, CancellationToken cancellationToken) in C:\projects\mysqlconnector\src\MySqlConnector\Core\ServerSession.cs:line 401
   at MySqlConnector.Core.ConnectionPool.GetSessionAsync(MySqlConnection connection, Int32 startTickCount, IOBehavior ioBehavior, CancellationToken cancellationToken) in C:\projects\mysqlconnector\src\MySqlConnector\Core\ConnectionPool.cs:line 112
   at MySqlConnector.Core.ConnectionPool.GetSessionAsync(MySqlConnection connection, Int32 startTickCount, IOBehavior ioBehavior, CancellationToken cancellationToken) in C:\projects\mysqlconnector\src\MySqlConnector\Core\ConnectionPool.cs:line 141
   at MySql.Data.MySqlClient.MySqlConnection.CreateSessionAsync(ConnectionPool pool, Int32 startTickCount, Nullable`1 ioBehavior, CancellationToken cancellationToken) in C:\projects\mysqlconnector\src\MySqlConnector\MySql.Data.MySqlClient\MySqlConnection.cs:line 645
   at MySql.Data.MySqlClient.MySqlConnection.OpenAsync(Nullable`1 ioBehavior, CancellationToken cancellationToken) in C:\projects\mysqlconnector\src\MySqlConnector\MySql.Data.MySqlClient\MySqlConnection.cs:line 312
   at Dapper.SqlMapper.QueryAsync[T](IDbConnection cnn, Type effectiveType, CommandDefinition command) in C:\projects\dapper\Dapper\SqlMapper.Async.cs:line 419
   at HistoryController.Index(Int32 accountId) in /app/src/history-service/HistoryController.cs:line 53
   at HistoryController.Index(Int32 accountId) in /app/src/history-service/HistoryController.cs:line 58
   at HistoryController.Index(Int32 accountId) in /app/src/history-service/HistoryController.cs:line 58
   at Microsoft.AspNetCore.Mvc.Infrastructure.ActionMethodExecutor.TaskOfIActionResultExecutor.Execute(IActionResultTypeMapper mapper, ObjectMethodExecutor executor, Object controller, Object[] arguments)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeActionMethodAsync>g__Awaited|12_0(ControllerActionInvoker invoker, ValueTask`1 actionResultValueTask)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeNextActionFilterAsync>g__Awaited|10_0(ControllerActionInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.Rethrow(ActionExecutedContextSealed context)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.Next(State& next, Scope& scope, Object& state, Boolean& isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeInnerFilterAsync>g__Awaited|13_0(ControllerActionInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.<InvokeFilterPipelineAsync>g__Awaited|19_0(ResourceInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.<InvokeAsync>g__Logged|17_1(ResourceInvoker invoker)
   at Microsoft.AspNetCore.Routing.EndpointMiddleware.<Invoke>g__AwaitRequestTask|6_0(Endpoint endpoint, Task requestTask, ILogger logger)
   at Serilog.AspNetCore.RequestLoggingMiddleware.Invoke(HttpContext httpContext)
{% endhighlight %}

So, problem, obviously lies somewhere in connection to mysql. But why doesn't exception appear in logs? Why? This is actually important, because we could miss logs from production and I hate that. At this time I've already spent 4 hours dissecting my 200 lines service, trying to understand - who mutes my exception, who deserves most painful execution in history of mankind?

And finally, I have removed JsonFormatter (we have custom json formatter for Serilog, tailored to our company needs) from logger configuration and, voila, we see that beatiful exception as above. "Hmmmm", I thought, - "What happened? JsonFormatter is dumb and simple". So I injected the test code into controller and I've got another exception:

{% highlight text %}
System.NullReferenceException: Object reference not set to an instance of an object.
   at Serilog.Formatting.Json.JsonValueFormatter.WriteQuotedJsonString(String str, TextWriter output)
   at JsonFormatter.LogException(Exception exception, TextWriter output) in /app/src/Logger/JsonFormatter.cs:line 56
   at JsonFormatter.LogException(Exception exception, TextWriter output) in /app/src/Logger/JsonFormatter.cs:line 74
   at JsonFormatter.LogException(Exception exception, TextWriter output) in /app/src/Logger/JsonFormatter.cs:line 74
   at JsonFormatter.LogException(Exception exception, TextWriter output) in /app/src/Logger/JsonFormatter.cs:line 74
   at JsonFormatter.Format(LogEvent logEvent, TextWriter output) in /app/src/Logger/JsonFormatter.cs:line 29
   at HistoryController.Index(Int32 accountId) in /app/src/history-service/HistoryController.cs:line 61
   at HistoryController.Index(Int32 accountId) in /app/src/history-service/HistoryController.cs:line 68
   at HistoryController.Index(Int32 accountId) in /app/src/history-service/HistoryController.cs:line 68
   at Microsoft.AspNetCore.Mvc.Infrastructure.ActionMethodExecutor.TaskOfIActionResultExecutor.Execute(IActionResultTypeMapper mapper, ObjectMethodExecutor executor, Object controller, Object[] arguments)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeActionMethodAsync>g__Awaited|12_0(ControllerActionInvoker invoker, ValueTask`1 actionResultValueTask)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeNextActionFilterAsync>g__Awaited|10_0(ControllerActionInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.Rethrow(ActionExecutedContextSealed context)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.Next(State& next, Scope& scope, Object& state, Boolean& isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ControllerActionInvoker.<InvokeInnerFilterAsync>g__Awaited|13_0(ControllerActionInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.<InvokeFilterPipelineAsync>g__Awaited|19_0(ResourceInvoker invoker, Task lastTask, State next, Scope scope, Object state, Boolean isCompleted)
   at Microsoft.AspNetCore.Mvc.Infrastructure.ResourceInvoker.<InvokeAsync>g__Logged|17_1(ResourceInvoker invoker)
   at Microsoft.AspNetCore.Routing.EndpointMiddleware.<Invoke>g__AwaitRequestTask|6_0(Endpoint endpoint, Task requestTask, ILogger logger)
   at Serilog.AspNetCore.RequestLoggingMiddleware.Invoke(HttpContext httpContext)
   at Microsoft.AspNetCore.ResponseCompression.ResponseCompressionMiddleware.Invoke(HttpContext context)
   at App.Metrics.AspNetCore.Tracking.Middleware.ApdexMiddleware.Invoke(HttpContext context)
   at App.Metrics.AspNetCore.Tracking.Middleware.PerRequestTimerMiddleware.Invoke(HttpContext context)
   at App.Metrics.AspNetCore.Tracking.Middleware.RequestTimerMiddleware.Invoke(HttpContext context)
   at App.Metrics.AspNetCore.Tracking.Middleware.ErrorRequestMeterMiddleware.Invoke(HttpContext context)
   at App.Metrics.AspNetCore.Tracking.Middleware.ActiveRequestCounterEndpointMiddleware.Invoke(HttpContext context)
   at Microsoft.AspNetCore.Server.Kestrel.Core.Internal.Http.HttpProtocol.ProcessRequests[TContext](IHttpApplication`1 application)
{% endhighlight %}

Gotcha! Line 56 is where we're passing stacktrace to serilog method that should format a string. That [method](https://github.com/serilog/serilog/blob/8ae332d983b31044f4da0fa34e3b9cb85ba68bc9/src/Serilog/Formatting/Json/JsonValueFormatter.cs#L298) assumes that passed string isn't null. And this is public API. So, let's talk about broken promises. We're getting to broken promises part of the
story.

In my project file I have this code:

{% highlight xml %}
    <PropertyGroup>
        <OutputType>Exe</OutputType>
        <TargetFramework>netcoreapp3.1</TargetFramework>
        <LangVersion>latest</LangVersion>
        <Nullable>enable</Nullable>
        <WarningsAsErrors>true</WarningsAsErrors>
        <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    </PropertyGroup>
{% endhighlight %}

As you can see, nullable feature of C#8 is enabled. All warnings are propagated to errors. Nuget package with logger was published, that means that compilation was successful, that means that we do not pass anywhere something that is nullable to non-nullable APIs, right? Let's look to signature of the method: `public static void WriteQuotedJsonString(string str, TextWriter output)`

`str` isn't nullable! There is no question mark there! So, if [stacktrace](https://docs.microsoft.com/en-us/dotnet/api/system.exception.stacktrace?view=netcore-3.1) property is nullable, compiler should emit error in our case. But it doesn't. Promise about "null safety" is broken. But why? Answer to that is third part of my story. It's about design decisions. You see, C# is a language, one of many in .net world. And feature of nullable reference types was introduced on language level, not on runtime level. That means that nullable string and non-nullable string to runtime are the same types. There is no real difference. And compiler emits some attributes on types to mark them either nullable or not. So, Serilog package was compiled either before that feature was introduced to C#, or with disabled feature, so no attributes on types.

And that was a story about bad design decisions. From my point of view, being able to check if type is nullable or not on runtime level is very important and worth of breaking backward compatibility. Current implementation, where `string` and `string?` are essentially same types, with no real ability of differintiate between them - is just bad decision, which led me, and will lead
other people, into false sense of safety: "see, zero errors with nullable enabled! We can't get NRE!" "Yes, sweet summer child, you can".

End of story.
