//
//  main.m
//  SocketDemo
//
//  Created by 魏欣宇 on 2018/4/22.
//  Copyright © 2018年 Dino. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <arpa/inet.h>

static const short SERVER_PORT = 6666;  //端口号

static const int MAX_Q_LEN = 64;        //最大队列长度

static const int MAX_MSG_LEN = 4000;    //最大消息长度

// 字符串截断函数
void change_enter_to_tail_zero(char * const buffer, int pos) {
    for (int i = pos - 1; i >= 0; i--)
    {
        if (buffer[i] == '\r')
        {
            buffer[i] = '\0';
            break;
        }
    }
}

void handle_client_connection(int clientSocketFD){
    bool clientConnected = true;
    while (clientConnected)
    {
        // C语言的数组结束符是'\0' 所以数组的实际长度是 MAX_MSG_LEN + 1
        char buffer[MAX_MSG_LEN + 1];
        
        
        /**
         不论是客户还是服务器应用程序都用recv函数从TCP连接的另一端接收数据。
         
         param clientSocketFD 客户端套接字文件句柄
         param buffer 存放接受信息的缓冲区
         param buffer - 1 是因为 bytesToRecv的信息存贮空间大小是 MAX_MSG_LEN
         param 0 一般设置为0
         return 如果是-1表示没有成功接收到客户端套接字的信息，否则就是成功接收到了信息
         */
        ssize_t bytes_to_recv = recv(clientSocketFD, buffer, sizeof buffer - 1, 0);
        if (bytes_to_recv > 0)
        {
            buffer[bytes_to_recv] = '\0'; //把buffer字符数组最后一个设置为\0 “字符串结束符” 注意：数组角标是0开始的。
            change_enter_to_tail_zero(buffer, (int)bytes_to_recv); //1.字符串的截断。通过在字符数组后面添加 '\0'即可。
            printf("%s\n", buffer);
            if (!strcmp(buffer, "bye"))
            {
                //通过匹配 bye 字符串来关闭链接。
                clientConnected = false;
            }
            
            /**
             不论是客户端还是服务器应用程序都用send函数来向TCP连接的另一端发送数据
             
             param 客户发送端套接字的描述符
             param buffer存放要发送数据的缓冲去
             param 实际要发送数据的字节数
             param 0 一般做保留
             return 如果是-1表示没有成功发送到信息，否则就是成功发送信息
             */
            ssize_t bytesToSend = send(clientSocketFD, buffer,
                                       bytes_to_recv, 0);
            if (bytesToSend > 0)
            {
                printf("Echo message has been sent.\n");
            }
        }
        else
        {
            //如果接受到内容，说明链接失败
            printf("client socket closed!\n");
            clientConnected = false;
        }
    }
    
    close(clientSocketFD); //关闭客户端Soket
}



int main() {
    
    /**
     创建一个服务端socket对象

     param AF_INET 指定使用IPV4协议
     param SOCK_STREAM 指定使用TCP协议 (SOCK_DGRAM 基于UDP的)
     return 如果返回的是-1,表示创建失败，否则表示创建成功
     */
    int server_socket_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket_fd < 0)
    {
        NSLog(@"---server_socket_fd：%d---", server_socket_fd);
        perror("---无法创建套接字server_socket_fd---\n");
    }
    
    struct sockaddr_in server_addr;
    server_addr.sin_family = AF_INET;                 // 指定IPV4
    server_addr.sin_port = htons(SERVER_PORT);        // 设置端口
    server_addr.sin_addr.s_addr = htonl(INADDR_ANY);  //INADDR_ANY 设置监听所有的地址。这里我们使用127.0.0.1.（使用telent命令进行测试后，6666端口被占用，可以通过 kill pid 来关闭占用该接口的进程。）
    
    int ret = bind(server_socket_fd, (struct sockaddr *)&server_addr, sizeof server_addr);
    if (ret < 0)
    {
        perror("无法将套接字绑定到指定的地址\n");
        close(server_socket_fd);
        exit(1);
    }
    
    
    /**
     server_socket_fd监听通过sreverAddr进入socket的TCP链接

     @param server_socket_fd 服务端socket对象
     @param MAX_Q_LEN 监听队列上的最大监听队列长度
     @return 是否成功开启监听
     */
    ret = listen(server_socket_fd, MAX_Q_LEN);
    if (ret < 0)
    {
        perror("无法开启监听\n");
        close(server_socket_fd);
        exit(1);
    }
    
    //设定一个死循环，让服务端一直处于开启状态。
    while (true)
    {
        struct sockaddr_in client_addr;  //创建一个socket客户端地址
        socklen_t client_addr_len = sizeof client_addr;
        
        /**
         该函数为每一个TCP链接创建一个新的套接字，之后从监听队列上移除该链接请求。

         param server_socket_fd 服务端的socket文件句柄
         param &client_addr 客户端socket的地址
         return 客户端的socket文件对象句柄，注意该客户端socket对象是通过sockaddr_in和accept俩进行创建的。
         */
        int client_socket_fd = accept(server_socket_fd, (struct sockaddr *)&client_addr, &client_addr_len);
        
        if (client_socket_fd < 0)
        {
            perror("接受客户端连接时发生的错误\n");
        }
        else
        {
            //在子线程中异步执行客户端的socket。
            dispatch_async(dispatch_get_main_queue(), ^{
                handle_client_connection(client_socket_fd);
            });
        }
    }
    
    return 0;
}


