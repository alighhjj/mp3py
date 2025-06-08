<#
.SYNOPSIS
    Git自动化提交和推送脚本
.DESCRIPTION
    自动检测是否为首次设置，执行相应的初始化或更新操作
    支持交互式输入提交信息和选择推送分支
    增加了超时处理机制，避免远程分支查询卡死
#>

# 函数：检测是否为Git仓库
function Test-GitRepository {
    <#
    .SYNOPSIS
        检测当前目录是否为Git仓库
    .DESCRIPTION
        通过检查.git目录是否存在来判断
    #>
    return Test-Path ".git"
}

# 函数：检测是否已配置远程仓库
function Test-RemoteOrigin {
    <#
    .SYNOPSIS
        检测是否已配置origin远程仓库
    .DESCRIPTION
        通过git remote命令检查是否存在origin配置
    #>
    $remotes = git remote
    return $remotes -contains "origin"
}

# 函数：初始化Git仓库
function Initialize-GitRepository {
    <#
    .SYNOPSIS
        初始化Git仓库并配置远程仓库
    .DESCRIPTION
        执行git init和git remote add origin操作
    #>
    Write-Host "检测到这是首次设置，开始初始化Git仓库..." -ForegroundColor Yellow
    
    # 初始化Git仓库
    Write-Host "初始化Git仓库..." -ForegroundColor Green
    git init
    
    # 获取远程仓库地址
    $remoteUrl = Read-Host "请输入远程仓库地址 (例如: https://github.com/username/repository.git)"
    
    # 添加远程仓库
    Write-Host "添加远程仓库..." -ForegroundColor Green
    git remote add origin $remoteUrl
    
    Write-Host "Git仓库初始化完成！" -ForegroundColor Green
}

# 函数：带超时的远程分支查询
function Get-RemoteBranchesWithTimeout {
    <#
    .SYNOPSIS
        带超时控制的远程分支查询函数
    .DESCRIPTION
        使用PowerShell作业实现超时控制，避免git ls-remote命令卡死
    .PARAMETER TimeoutSeconds
        超时时间（秒），默认15秒
    #>
    param(
        [int]$TimeoutSeconds = 15
    )
    
    try {
        Write-Host "查询远程分支..." -ForegroundColor Green
        
        # 使用Start-Job实现超时控制
        $job = Start-Job -ScriptBlock {
            git ls-remote --heads origin 2>&1
        }
        
        # 等待作业完成或超时
        $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds
        
        if ($completed) {
            $result = Receive-Job -Job $job
            Remove-Job -Job $job
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host $result
                return $true
            } else {
                Write-Host "远程分支查询失败: $result" -ForegroundColor Red
                return $false
            }
        } else {
            Stop-Job -Job $job
            Remove-Job -Job $job
            Write-Host "远程分支查询超时（${TimeoutSeconds}秒）" -ForegroundColor Red
            Write-Host "可能的原因：网络连接问题、远程仓库认证失败或地址错误" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "远程分支查询出错: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# 函数：执行提交和推送操作
function Invoke-GitCommitAndPush {
    <#
    .SYNOPSIS
        执行Git提交和推送操作
    .DESCRIPTION
        添加文件、提交更改、查询远程分支并推送到指定分支
    #>
    # 添加修改的文件
    Write-Host "添加修改的文件..." -ForegroundColor Green
    git add .
    
    # 检查是否有文件需要提交
    $status = git status --porcelain
    if (-not $status) {
        Write-Host "没有文件需要提交" -ForegroundColor Yellow
        return
    }
    
    # 交互式输入提交信息
    Write-Host "请输入提交信息:" -ForegroundColor Green
    $commitMessage = Read-Host "提交信息"
    
    # 验证提交信息不为空
    while ([string]::IsNullOrWhiteSpace($commitMessage)) {
        Write-Host "提交信息不能为空，请重新输入:" -ForegroundColor Red
        $commitMessage = Read-Host "提交信息"
    }
    
    # 执行提交
    Write-Host "提交更改..." -ForegroundColor Green
    git commit -m "$commitMessage"
    
    # 尝试查询远程分支（带超时）
    $remoteBranchSuccess = Get-RemoteBranchesWithTimeout -TimeoutSeconds 15
    
    if (-not $remoteBranchSuccess) {
        Write-Host "`n无法查询远程分支，将使用默认选项" -ForegroundColor Yellow
        Write-Host "建议检查网络连接和远程仓库配置" -ForegroundColor Yellow
        Write-Host "可以使用命令检查：git remote -v" -ForegroundColor Yellow
    }
    
    Write-Host "`n请选择要推送的分支:" -ForegroundColor Yellow
    Write-Host "1. main"
    Write-Host "2. master"
    Write-Host "3. 当前分支 ($(git branch --show-current))"
    
    $choice = Read-Host "请输入选择 (1-3)"
    
    switch ($choice) {
        "1" { 
            Write-Host "推送到 main 分支..." -ForegroundColor Cyan
            git push -u origin main
        }
        "2" { 
            Write-Host "推送到 master 分支..." -ForegroundColor Cyan
            git push -u origin master
        }
        "3" { 
            $currentBranch = git branch --show-current
            Write-Host "推送到当前分支 $currentBranch..." -ForegroundColor Cyan
            git push -u origin $currentBranch
        }
        default { 
            Write-Host "无效选择，请重新运行脚本" -ForegroundColor Red
            return
        }
    }
    
    Write-Host "操作完成！" -ForegroundColor Green
}

# 主程序逻辑
try {
    Write-Host "=== Git自动化脚本 ===" -ForegroundColor Magenta
    
    # 检测是否为首次设置
    if (-not (Test-GitRepository) -or -not (Test-RemoteOrigin)) {
        # 首次设置：执行初始化
        Initialize-GitRepository
        
        # 询问是否继续提交
        $continueCommit = Read-Host "`n是否继续执行提交操作？(y/n)"
        if ($continueCommit -eq 'y' -or $continueCommit -eq 'Y') {
            Invoke-GitCommitAndPush
        }
    } else {
        # 非首次设置：直接执行提交和推送
        Write-Host "检测到已存在的Git仓库，执行更新提交..." -ForegroundColor Green
        Invoke-GitCommitAndPush
    }
} catch {
    Write-Host "脚本执行出错: $($_.Exception.Message)" -ForegroundColor Red
}