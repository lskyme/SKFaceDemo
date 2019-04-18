# SKFaceDemo

！！！！需要在真机下运行！！！！

**Demo提供了两种方式：
1、OpenCV与dlib
2、[虹软](https://www.arcsoft.com.cn/)提供的[ArcFace](https://ai.arcsoft.com.cn/product/arcface.html)与dlib**

因github上传限制，opencv和ArcFace不包含在本demo中，请到[OpenCV官网](https://opencv.org/releases/)直接下载framework或下载sources自行使用CMake编译framework，并放到项目opencv2目录下。
ArcFace需要到[虹软](https://www.arcsoft.com.cn/)注册账号和应用，再下载[ArcFace](https://ai.arcsoft.com.cn/product/arcface.html)。将SDK放入项目engines目录下；并在*ArcsoftImageViewController*和*ArcsoftVideoViewController*中填入AppId和对应的AppKey。
>dlib库包含在demo中，无需另做处理。

![arcface](https://github.com/lskyme/SKFaceDemo/blob/master/pics/arcface.png?raw=true)

>此处实际上只需要*PLATFORM*、*arcsoft_fsdk_face_detection*、*arcsoft_fsdk_face_tracking*和*arcsoft_fsdk_base.framework*即可。

![appid](https://github.com/lskyme/SKFaceDemo/blob/master/pics/appid.png?raw=true)

运行后，测试图片点击人脸检测，测试视频点击人脸追踪。

![mainpage](https://github.com/lskyme/SKFaceDemo/blob/master/pics/IMG_0055.PNG?raw=true)

![program](https://github.com/lskyme/SKFaceDemo/blob/master/pics/IMG_0056.PNG?raw=true)

提供人脸区域标记及人脸特征点标记按钮，可以动态切换。

经测试，ArcFace比OpenCV在识别准确性和性能上都要更好。

Demo仅供研究使用，ArcFace是付费SDK，商用需要联系[提供商](https://www.arcsoft.com.cn/)。

如您发现bug，请帮忙提交issue或联系我的邮箱lskyme@sina.com，如果觉得Demo不错，可以star一下，谢谢！

