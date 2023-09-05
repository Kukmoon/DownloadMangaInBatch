# 想把最后一张图的 URI，例如，https://hnt.javmobile.mobi/000/022/22751/34.jpg，拆分成前面的路径和最后的文件
# $URI="https://hnt.javmobile.mobi/000/022/22751/34.jpg"
Param([string]$URI) 

# 如果没有以命令行方式输入最后一张图的 URI，那么，就在 PowerShell 窗口中提示用户手工输入
If($URI)
{
    Write-Host $URI
}
else
{
    $URI = Read-Host "请输入漫画最后一张图片的完整 URI，例如 https://hnt.javmobile.mobi/000/022/22751/34.jpg "
}

# 解析 URI，例如，把 https://hnt.javmobile.mobi/000/022/22751/34.jpg 转换成 https://hnt.javmobile.mobi/000/022/22751/$i.jpg 的形式
# 因为 PowerShell 5.1 的 Split 命令不支持从后往前寻找分隔符并分割字符串，因此只能写一个循环来解决，
# 如果是用 PowerShell 7.x，那么一句 $split = $URI -split '/' , -2，就完事了。
$split = $URI -split '/'
$result = -Join ($split[0],'//',$split[2],'/')
For ($i=3; $i -ile $split.Count-2;$i++)
{
    $result = -Join ($result,$split[$i],'/')
}
$URIpath=$result
$Filename=$split[$split.Count-1]
$Pages=$filename.split('.')[0]
$Ext=$filename.split('.')[-1]

New-Item -Path . -Name "output" -ItemType "directory"

# 用 For 循环结合 Invoke-WebRequest 命令（或 Start-BitsTransfer 命令）下载漫画的每一页
For ($i=1; $i -ile $Pages; $i++)
{
    $FullURI = -Join ($URIPath,$i,'.',$Ext)
    Start-BitsTransfer -Source $FullURI -Destination .\output\$i.jpg -ProxyUsage Override -ProxyList 127.0.0.1:7890
    # 也可以用这个：  Invoke-WebRequest -Uri $URI -OutFile .\output\$i.jpg -Proxy http://127.0.0.1:7890
    
    # 注意：关于代理
    # 1. 上述两条命令已经分别单独指定代理为 http://127.0.0.1:7890
    # 2. Invoke-WebRequest 命令要用 -Proxy 开关指定代理，代理的地址要有 http:// 前缀
    # 3. Start-BitsTransfer 命令要用 -ProxyUsage Override 开关强制启用代理，用 -ProxyList 开关指定代理，代理的地址不能有 http:// 前缀
    # 4. 如果不需要代理，需要手工去掉上述开关
}

# 用 For 循环结合 Rename-Item 命令把 1.jpg、2.jpg … 9.jpg 命名为01.jpg、02.jpg … 09.jpg
For ($i=1; $i -ile 9; $i++)
{
    Rename-Item -Path ".\Output\$i.jpg" -NewName "0$i.jpg"
}

# 用 Compress-Archive 命令将所有 JPG 文件打包压缩
Compress-Archive -Path .\output\*.* -DestinationPath .\comic.zip -Force

Remove-Item -Path .\output -Recurse -Force