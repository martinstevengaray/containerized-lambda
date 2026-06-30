package com.mgaray.server;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;

/**
 * Plain HTTP echo server with a {@code main} method and no AWS Lambda dependency.
 *
 * <p>The process owns its own lifecycle and speaks ordinary HTTP. When deployed to Lambda, the
 * AWS Lambda Web Adapter (an extension baked into the container image) translates Lambda Runtime
 * API invocations into HTTP requests against this server on {@code $PORT}. Because the app is a
 * normal web server, it can later handle anything HTTP can express (streaming, custom routes,
 * other frameworks) without being constrained by the Lambda handler model.
 */
public class Server {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    public static void main(String[] args) throws IOException {
        int port = Integer.parseInt(System.getenv().getOrDefault("PORT", "8080"));
        HttpServer server = HttpServer.create(new InetSocketAddress(port), 0);
        server.createContext("/", com.mgaray.server.Server::handle);
        server.setExecutor(Executors.newFixedThreadPool(8));
        server.start();
        System.out.println("echo server listening on port " + port);
    }

    private static void handle(HttpExchange exchange) throws IOException {
        byte[] requestBody = exchange.getRequestBody().readAllBytes();

        ObjectNode echo = MAPPER.createObjectNode();
        echo.put("message", "echo");
        echo.put("method", exchange.getRequestMethod());
        echo.put("path", exchange.getRequestURI().getPath());
        echo.put("query", exchange.getRequestURI().getRawQuery());

        ObjectNode headers = echo.putObject("headers");
        for (Map.Entry<String, List<String>> header : exchange.getRequestHeaders().entrySet()) {
            headers.put(header.getKey(), String.join(",", header.getValue()));
        }
        echo.put("body", new String(requestBody, StandardCharsets.UTF_8));

        byte[] response = MAPPER.writeValueAsBytes(echo);
        exchange.getResponseHeaders().set("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, response.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(response);
        }
    }
}
