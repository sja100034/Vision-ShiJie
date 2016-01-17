//
//  TRWeiboViewController.m
//  xiangmu
//
//  Created by tarena on 16/1/16.
//  Copyright © 2016年 tarena. All rights reserved.
//

#import "TRWeiboViewController.h"
#import "AFNetworking.h"

#import "SJUserinfo.h"
#import "SJXmpptool.h"
#import "ViewController.h"

#import "kkkViewController.h"

#define  APPKEY       @"2075708624"
#define  REDIRECT_URI @"http://www.tedu.cn"
#define  APPSECRET    @"36a3d3dec55af644cd94a316fdd8bfd8"

//对于webview的 形式，最主要的是要遵守协议，实现代理

@interface TRWeiboViewController ()<UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webview;


@end

@implementation TRWeiboViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
#warning 对于第三方，我们用的是 微博开放平台上的 Oauth2/authorize 这一个，进行加载的数据
    
    
    
    self.webview.delegate = self ;
    
    NSString* strurl = [NSString stringWithFormat:@"https://api.weibo.com/oauth2/authorize?client_id=%@&redirect_uri=%@",APPKEY,REDIRECT_URI];
    
    //有了 url 就可以发送请求
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:strurl]];
    
    //然后把请求后的数据，加载到 webview 上、
    
    [self.webview loadRequest:request];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{

    NSLog(@"%@",request.URL.absoluteString);
    
    //根据这一个 request 来找到申请access——token 的 code
    
    NSString* urlstr = request.URL.absoluteString ;
    
    //他的目的 就是获得 这一段 字符串的 长度
    
    NSRange range = [urlstr rangeOfString:[NSString stringWithFormat:@"%@/?code=",REDIRECT_URI]];
    
    NSString* code = nil ;
    
    if (range.length > 0) {
        
        NSUInteger index = range.length ;
        
        //在这里我们就生成了 ，要申请 access token的 code
        
        code = [urlstr substringFromIndex:index];
        
        NSLog(@"%@",code);
        
        //因为在这里得到了code ，所以，就可以根据这一个code 获得access_token，这一个值
        
        [self getaccesstoken:code];
        
        
        
        //return no 就是 不让他跳转到 达内的界面
        return NO ;
        
        
    }
    return  YES ;
}


//在这里。要写具体的申请 access_token的实现，当然要写一个方法，这个方法中是有传参的



-(void)getaccesstoken:(NSString*)code{

//在这里面写具体的实现逻辑 ,因为只能是 post 请求
    
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    
    NSString* urlstr = @"https://api.weibo.com/oauth2/access_token?";
    
    NSMutableDictionary* dic = [NSMutableDictionary dictionary];
    
    dic[@"client_id"] =  APPKEY ;
    
    dic[@"client_secret"] = APPSECRET ;
    
    dic[@"grant_type"] = @"authorization_code"; ;
    
    dic[@"code"] = code ;
    
    dic[@"redirect_uri"] = REDIRECT_URI ;
    
    
    [manager POST:urlstr parameters:dic success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        
        NSLog(@"%@",responseObject);
        
        //在这里我们得到access_token之后,用这些返回的数据，作为注册 和登陆的 用户名还有密码
        
        //把得到的消息 转化成内部的 注册 和 登录账号
        
        [SJUserinfo sharedSJUserinfo].reginster = YES ;
        
        [SJUserinfo sharedSJUserinfo].reginstername = responseObject[@"uid"];
        
        [SJUserinfo sharedSJUserinfo].reginsterpassword = responseObject[@"access_token"];
        
      
        
        //然后 调用 注册 方法
        
        __weak typeof(self) vc = self ;
        
        [[SJXmpptool sharedSJXmpptool] userreginstermethod:^(SJReginsterType type) {
           
#warning 使用 block 最主要的 要注意的 就是 强引用的问题
            
            [vc handlerehinster:type];
        }];
        
     } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        
        NSLog(@"%@",error);
    }];
}


//在这里实现 注册的基本逻辑

-(void)handlerehinster:(SJReginsterType)type{

    switch (type) {
        case SJReginstersuccessful:
            //如果注册 成功，那也要在 web 服务器上 注册一个
            
            [self webreginster];
            
            
            
       case SJRegiinsterfailed:
        //无论注册成功与否 ，都要登录
            //无论注册成功与否 ，都登陆
        {
            [SJUserinfo sharedSJUserinfo].reginster = NO ;
            
            [SJUserinfo sharedSJUserinfo].loginname = [SJUserinfo sharedSJUserinfo].reginstername ;
            
            [SJUserinfo sharedSJUserinfo].lopginpassword = [SJUserinfo sharedSJUserinfo].reginsterpassword ;
            
            
            [[SJXmpptool sharedSJXmpptool]userloginmethod:^(SJReginsterType type) {
               
                [self handlelogin:type];
                
            }];
            
        }
            break;
            
            case KRXMPPResultTypeNetError:
            
            NSLog(@"网络错误");
            
            break ;
            
    }

}



-(void)handlelogin:(SJReginsterType)type{

    switch (type) {
        case SJLoginsuccess:
        {
            [SJUserinfo sharedSJUserinfo].sinalogin = YES    ;
            
            //登录成功 跳转到 主界面
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"kkk" bundle:nil];
            
            [UIApplication sharedApplication].keyWindow.rootViewController = storyboard.instantiateInitialViewController;
            
//            kkkViewController* vc = [[kkkViewController alloc]init];
//            
//            UINavigationController* avc = [[UINavigationController alloc]initWithRootViewController:vc];
//            
//            [self presentViewController:avc animated:YES completion:nil];
//            
           // [self dismissViewControllerAnimated:YES completion:nil];
            
            
        }
            break;
            
       case SJLoginfailed:
            
            NSLog(@"错误");
            
            break;
    }



}



-(void)webreginster{
    
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];

    NSString* str = [NSString stringWithFormat:@"http://%@:8080/allRunServer/register.jsp",SJXMPPHOSTNAME];
    
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    
    parameters[@"username"] = [SJUserinfo sharedSJUserinfo].reginstername ;
    
    parameters[@"md5password"] = [SJUserinfo sharedSJUserinfo].reginsterpassword ;
    
    [manager POST:str parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        //在这里 上传 图片
        
        UIImage* iamge = [UIImage imageNamed:@"select1@2x.png"];
        
        NSData* data = UIImagePNGRepresentation(iamge);
        
        [formData appendPartWithFileData:data name:@"pic" fileName:@"image.png" mimeType:@"image/jpeg"];
        
        
        
        
    } success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        
        NSLog(@"%@",responseObject);
        
        
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        
        NSLog(@"%@",error);
    }];
    



}












@end
