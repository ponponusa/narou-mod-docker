#
# narou-mod Docker コンテナのビルドと起動スクリプト
#
# Copyright (c) 2025 ponponusa
#

param(
    [switch]$Rebuild
)

try {
    # 設定ファイルの読み込み
    Write-Host "Reading configuration from .env file..."
    $EnvFile = Join-Path $PSScriptRoot ".env"
    if (-not (Test-Path $EnvFile)) {
        throw ".env file not found at $EnvFile"
    }

    # .env ファイルを読み込み、ハッシュテーブルに格納
    $Config = @{}
    Get-Content $EnvFile -Encoding UTF8 | ForEach-Object {
        $line = $_.Trim()
        # コメント行と空行をスキップ
        if ($line -match '^[^#]' -and $line -match '=') {
            $key, $value = $line -split '=', 2
            $Config[$key.Trim()] = $value.Trim()
        }
    }

    # 読み込んだ設定を変数に展開
    $APP_NAME = $Config["APP_NAME"]
    $HOST_NOVEL_PATH = $Config["HOST_NOVEL_PATH"]
    $UID = $Config["UID"]
    $GID = $Config["GID"]
    $HOST_P1 = $Config["HOST_P1"]
    $HOST_P2 = $Config["HOST_P2"]
    $NAROU_MOD_VERSION = $Config["NAROU_MOD_VERSION"]
    $NAROU_MOD_GEM_LOCAL_FILE = $Config["NAROU_MOD_GEM_LOCAL_FILE"]
    $AOZORAEPUB3_VERSION = $Config["AOZORAEPUB3_VERSION"]
    $AOZORAEPUB3_ZIP_LOCAL_FILE = $Config["AOZORAEPUB3_ZIP_LOCAL_FILE"]
    $KINDLEGEN_TAR_LOCAL_FILE = $Config["KINDLEGEN_TAR_LOCAL_FILE"]
    $KINDLEGEN_URL = $Config["KINDLEGEN_URL"]
    $KINDLEGEN_FILE = $Config["KINDLEGEN_FILE"]

    Write-Host "APP_NAME: $APP_NAME"
    Write-Host "HOST_NOVEL_PATH: $HOST_NOVEL_PATH"
    Write-Host "UID / GID: $UID / $GID"
    Write-Host "PORTS: $HOST_P1, $HOST_P2"
    Write-Host "NAROU_MOD_VERSION: $NAROU_MOD_VERSION"
    Write-Host "NAROU_MOD_GEM_LOCAL_FILE: $NAROU_MOD_GEM_LOCAL_FILE"
    Write-Host "AOZORAEPUB3_ZIP_LOCAL_FILE: $AOZORAEPUB3_ZIP_LOCAL_FILE"
    Write-Host "KINDLEGEN_TAR_LOCAL_FILE: $KINDLEGEN_TAR_LOCAL_FILE"
    Write-Host "KINDLEGEN_URL: $KINDLEGEN_URL"
    Write-Host "KINDLEGEN_FILE: $KINDLEGEN_FILE"

    # ホスト側パスの構築
    $ScriptDir = $PSScriptRoot

    # $HOST_NOVEL_PATH が絶対パスか相対パスかを判定
    if ([System.IO.Path]::IsPathRooted($HOST_NOVEL_PATH)) {
        # 絶対パスの場合 (例: C:\novel)
        $HostPath = $HOST_NOVEL_PATH
        Write-Host "Using absolute host path: $HostPath"
    }
    else {
        # 相対パスの場合 (例: my-novels)
        $HostPath = Join-Path $ScriptDir $HOST_NOVEL_PATH
        Write-Host "Using relative host path. Full path: $HostPath"
    }

    # フォルダが存在しない場合は作成する
    if (-not (Test-Path $HostPath)) {
        Write-Host "Creating host directory at: $HostPath"
        New-Item -ItemType Directory -Path $HostPath
    }

    # Dockerイメージの確認とビルド
    # - docker-desktop が起動しているか軽くチェック
    docker ps -q -n 1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Docker Desktop does not seem to be running. Please start it and try again."
    }

    # -Rebuild が指定された場合にイメージを削除
    $Image = docker images -q $APP_NAME
    if ($Rebuild -and (-not [string]::IsNullOrEmpty($Image))) {
        Write-Host "Rebuild flag detected. Removing existing image: $APP_NAME"
        docker rmi $APP_NAME
        $Image = $null # ビルドを強制するためにクリア
    }

    # イメージが存在しない場合にビルドを実行
    if ([string]::IsNullOrEmpty($Image)) {
        Write-Host "Image $APP_NAME not found or rebuild forced. Building image..."
        docker build -t $APP_NAME `
            --build-arg "NAROU_MOD_VERSION=$($NAROU_MOD_VERSION)" `
            --build-arg "NAROU_MOD_GEM_LOCAL_FILE=$($NAROU_MOD_GEM_LOCAL_FILE)" `
            --build-arg "AOZORAEPUB3_VERSION=$($AOZORAEPUB3_VERSION)" `
            --build-arg "AOZORAEPUB3_ZIP_LOCAL_FILE=$($AOZORAEPUB3_ZIP_LOCAL_FILE)" `
            --build-arg "KINDLEGEN_TAR_LOCAL_FILE=$($KINDLEGEN_TAR_LOCAL_FILE)" `
            --build-arg "KINDLEGEN_URL=$($KINDLEGEN_URL)" `
            --build-arg "KINDLEGEN_FILE=$($KINDLEGEN_FILE)" `
            .
        
        if ($LASTEXITCODE -ne 0) {
            throw "Docker build failed."
        }
        Write-Host "Image $APP_NAME built successfully."
    }
    else {
        Write-Host "Image $APP_NAME already exists. Skipping build."
    }

    # 既存コンテナの停止と削除
    $ExistingContainer = docker ps -a -q --filter "name=$APP_NAME"
    if (-not [string]::IsNullOrEmpty($ExistingContainer)) {
        Write-Host "Stopping and removing existing container: $APP_NAME"
        docker stop $APP_NAME | Out-Null
        docker rm $APP_NAME | Out-Null
    }

    # Dockerコンテナの起動
    Write-Host "Starting container $APP_NAME..."
    Write-Host "Mapping host path '$HostPath' to '/home/narou' in container."
    Write-Host "Mapping ports $HOST_P1 -> $HOST_P1 and $HOST_P2 -> $HOST_P2"

    # インストール設定を表示
    Write-Host "NAROU_MOD_VERSION: $NAROU_MOD_VERSION"
    Write-Host "NAROU_MOD_GEM_LOCAL_FILE: $NAROU_MOD_GEM_LOCAL_FILE"
    Write-Host "AOZORAEPUB3_VERSION: $AOZORAEPUB3_VERSION" 
    Write-Host "AOZORAEPUB3_ZIP_LOCAL_FILE: $AOZORAEPUB3_ZIP_LOCAL_FILE"
    Write-Host "KINDLEGEN_TAR_LOCAL_FILE: $KINDLEGEN_TAR_LOCAL_FILE"
    Write-Host "KINDLEGEN_URL: $KINDLEGEN_URL"
    Write-Host "KINDLEGEN_FILE: $KINDLEGEN_FILE"

    # docker run を実行
    docker run -d --name $APP_NAME `
        -p "$($HOST_P1):$($HOST_P1)" `
        -p "$($HOST_P2):$($HOST_P2)" `
        -v "$($HostPath):/home/narou/novel" `
        -e "HOME=/home/narou" `
        -e "HOST_NOVEL_PATH=$($HostPath)" `
        -e "UID=$($UID)" `
        -e "GID=$($GID)" `
        -e "P1=$($HOST_P1)" `
        -e "P2=$($HOST_P2)" `
        -e "NAROU_MOD_VERSION=$($NAROU_MOD_VERSION)" `
        -e "NAROU_MOD_GEM_LOCAL_FILE=$($NAROU_MOD_GEM_LOCAL_FILE)" `
        -e "KINDLEGEN_TAR_LOCAL_FILE=$($KINDLEGEN_TAR_LOCAL_FILE)" `
        -e "KINDLEGEN_URL=$($KINDLEGEN_URL)" `
        -e "KINDLEGEN_FILE=$($KINDLEGEN_FILE)" `
        $APP_NAME

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to start container $APP_NAME."
    }

    Write-Host "Container $APP_NAME started successfully."
    Write-Host "Access the application at http://localhost:$HOST_P1"

}
catch {
    Write-Error $_.Exception.Message
    exit 1
}