# 上传 GitHub

建议仓库名：`argo-cubesat-space-segment`。

建议 Description：`Preliminary 6U CubeSat space-segment design with MATLAB/SCT subsystem studies, preserved results and engineering traceability.`

建议 Topics：`cubesat`、`space-systems`、`matlab`、`attitude-control`、`systems-engineering`、`spacecraft`。

## 上传范围

只上传 `argo-cubesat-portfolio/` 内的内容。相邻的 `argo-local-archive/` 是本地原件归档，不要一起拖入仓库。课程工具箱、讲义和其他课程资料仍在原文件夹，没有放入上传包。

`argo-cubesat-portfolio.zip` 便于搬运；解压后上传里面的文件，GitHub 才能直接显示 README 和代码。不要仅上传 ZIP 当作仓库内容。

## 使用 Git

先在 GitHub 创建一个空仓库，不自动生成 README 或 License。然后在终端进入本文件夹，执行：

```bash
python3 tools/verify_integrity.py
git init
git add .
git status --short
git diff --cached --stat
git commit -m "Add preserved ARGO CubeSat assessment portfolio"
git branch -M main
```

复制你新仓库提供的 remote URL，再执行：

```bash
git remote add origin <复制的新仓库URL>
git push -u origin main
```

尖括号部分是需要替换的占位符。Git 身份和 GitHub 登录使用你自己的设置。本说明给出后续自行发布的操作步骤；实际发布状态以 GitHub 仓库为准。

## 使用网页上传

创建空仓库后使用上传文件入口，将本文件夹中的文件和子文件夹上传。确保 README 位于仓库根目录，并保留 `.gitignore` 和 `.gitattributes`。上传后检查 README 图像、文档链接和 `code/final/` 是否可访问。

## 发布后的展示顺序

把仓库加入个人主页的精选项目。面试时从英文 README 进入原始结果，再打开 ADCS/EPS 代码和技术边界文档。没有给混合来源材料自动添加开源许可；第三方来源见 `THIRD_PARTY_NOTICES.md`。
