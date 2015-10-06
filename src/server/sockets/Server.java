package server.sockets;

import common.ResourceManager;
import server.ResourceManagerImpl;

import common.sockets.RequestContext;
import common.sockets.RequestHandler;

import java.io.IOException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;

public class Server implements Runnable {

    public static final int BACKLOG_MULTIPLIER = 5;

    public final int THREAD_COUNT;

    final ExecutorService executorService;
    final ServerSocket serverSocket;
    final ResourceManager resourceManager;

    public Server(int port, InetAddress bindAddress, ResourceManager manager)
    throws IOException {
        resourceManager = manager;

        THREAD_COUNT = Runtime.getRuntime().availableProcessors();
        executorService = Executors.newFixedThreadPool(THREAD_COUNT);

        serverSocket = new ServerSocket(
                port,
                BACKLOG_MULTIPLIER * THREAD_COUNT,
                bindAddress
        );
    }

    @Override
    public void run() {
        boolean running = true;

        while(running) {
            try {
                final Socket clientSocket = serverSocket.accept();
                final RequestContext ctx =
                    new RequestContext.RequestContextBuilder()
                        .withResourceManager(resourceManager)
                        .withClientSocket(clientSocket)
                        .build();
                final RequestHandler handler = new RequestHandler(ctx);

                executorService.submit(handler);
            }
            catch(IOException e) {
                e.printStackTrace();
            }
        }
    }

    public static void main(String[] args)
    throws Exception {
        String address = args[0];
        int port = Integer.parseInt(args[1]);

        // TODO read a file with this configuration
        ResourceManager resourceManager = new ResourceManagerImpl(
                "jax",
                "",
                "jdbc:postgresql://localhost:5432/jax"
        );

        Server server = new ServerBuilder()
            .withListenPort(port)
            .withBindAddress(InetAddress.getByName(address))
            .withResourceManager(resourceManager)
            .build();

        server.run();

        System.out.println("RM Sockets Server is exiting. Have a nice day.");
    }

    public static class ServerBuilder {
        ResourceManager resourceManager;
        int listenPort;
        InetAddress bindAddress;

        public ServerBuilder() {

        }

        public ServerBuilder withResourceManager(ResourceManager rm) {
            resourceManager = rm;
            return this;
        }

        public ServerBuilder withListenPort(int port) {
            listenPort = port;
            return this;
        }

        public ServerBuilder withBindAddress(InetAddress address) {
            bindAddress = address;
            return this;
        }

        public Server build() throws IOException {
            return new Server(listenPort, bindAddress, resourceManager);
        }
    }
}
