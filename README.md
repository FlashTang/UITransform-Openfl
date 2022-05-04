## UITransform-Openfl
# 在akifox-transform的基础上集成了UI
依赖：[akifox-transform](https://github.com/yupswing/akifox-transform)

用法：
步骤1：安装依赖库：https://github.com/yupswing/akifox-transform
    ```
    haxelib install akifox-transform
    ```
    
步骤2: 在 project.xml 中添加:
    ```
    <haxelib name="akifox-transform" />
    ```
    
步骤3: 复制 UITransform.hx 文件到你的项目中

然后把你要进行变换的 DisplayObject（shape ,sprite, movieclip .. ) 加载到显示列表中
然后， 一句代码：
   ```
   UITransform.make(yourSprite);
   ```
   
# P.S. 没完成，目前只能旋转变换，拖动中心点以改变旋转中心


