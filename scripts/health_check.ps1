# 只读健康检查：从环境变量读取 Key，确认服务连通性与可用模型数量。
# 用法：$env:AGNES_API_KEY = "sk-..." ; ./health_check.ps1
param(
    [string]$BaseUrl = "https://api.agnes-ai.cn",
    [string]$EnvName = "AGNES_API_KEY"
)

$key = [Environment]::GetEnvironmentVariable($EnvName)
if (-not $key) {
    Write-Host "[SKIP] 环境变量 $EnvName 未设置" -ForegroundColor Yellow
    exit 2
}

try {
    $resp = Invoke-WebRequest -Uri "$BaseUrl/v1/models" -Headers @{ Authorization = "Bearer $key" } -TimeoutSec 20
    $models = ($resp.Content | ConvertFrom-Json).data
    Write-Host ("[OK] HTTP {0} | 可用模型 {1} 个" -f $resp.StatusCode, @($models).Count) -ForegroundColor Green
    @($models) | ForEach-Object { "  - " + $_.id }
}
catch {
    $code = $_.Exception.Response.StatusCode.value__
    switch ($code) {
        401 { Write-Host "[FAIL] 401 凭证无效" -ForegroundColor Red }
        403 { Write-Host "[FAIL] 403 档位不含该模型" -ForegroundColor Red }
        503 { Write-Host "[FAIL] 503 上游服务不可用（与本地配置无关）" -ForegroundColor Red }
        default { Write-Host ("[FAIL] " + $_.Exception.Message) -ForegroundColor Red }
    }
    exit 1
}
