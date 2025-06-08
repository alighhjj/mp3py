<#
.SYNOPSIS
    Git自动化提交和推送脚本
.DESCRIPTION
    自动检测是否为首次设置，执行相应的初始化或更新操作
    支持交互式输入提交信息和选择推送分支
#>

# 函数：检测是否为Git仓库
function Test-GitRepository {
    return Test-Path ".git"
}

# 函数：检测是否已配置远程仓库
function Test-RemoteOrigin {
    $remotes = git remote
    return $remotes -contains "origin"
}

# 函数：初始化Git仓库
function Initialize-GitRepository {
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

# 函数：执行提交和推送操作
function Invoke-GitCommitAndPush {
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
    
    # 显示远程分支并让用户选择
    Write-Host "查询远程分支..." -ForegroundColor Green
    git ls-remote --heads origin
    
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