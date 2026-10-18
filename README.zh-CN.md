# ARGO：6U CubeSat 空间段初步设计

本项目整理自 UNSW AERO9610「The Space Segment」2026 T1 assessment，面向 GitHub 展示和技术面试。重点是围绕一个立体视觉观测任务，解释轨道、结构、热控、电源、姿态控制、通信和数据管理之间的约束关系。

**项目定位：航天器系统设计与分系统仿真。** vSLAM、完整交会对接、目标相对导航闭环属于任务设想，现有代码未实现这些算法。

## 推荐阅读顺序

- [英文项目首页](README.md)：供招聘方快速了解设计和原始结果。
- [面试讲解稿](docs/INTERVIEW.zh-CN.md)：90 秒介绍、5 分钟演示、技术追问和简历表述。
- [Assessment 对照](docs/ASSESSMENT.md)：proposal → draft → final 的证据链。
- [原始结果图集](docs/RESULTS.md)：直接提取报告图像，未修改曲线。
- [版本说明](docs/VERSIONS.md)、[复现说明](docs/REPRODUCIBILITY.md)和[技术边界](docs/LIMITATIONS.md)：解释代码之间的差别及尚未验证的问题。
- [上传 GitHub](docs/GITHUB.zh-CN.md)：如何发布这个文件夹。

## 本次整理做了什么

保留 17 个公开包中的 MATLAB 文件、2 个历史 MAT 文件的原始字节；保留各阶段版本，未重命名脚本。新增 README、assessment 对照、来源记录、运行说明及面试稿。报告图片来自 PDF 中的嵌入图像，没有重新绘图。

两份带明确 PSS 版权声明的文件、原始 assessment 报告和评分材料存放在相邻的 `argo-local-archive/`；完整工具箱、讲义和参考文献仍在原课程文件夹。本项目没有自动上传 GitHub。

## 面试时要讲清楚

- 最终设计目标：6U / 9 kg / 500 km，60 Wh 电池，四反作用轮 PID，S-band 1.2 Mbps。
- 报告展示了电池能量和姿态误差等结果；本次整理没有成功重新运行 MATLAB，因此不能称为“已复现通过”。
- 各脚本存在不同参数与不同模型；不能称为已经完成统一的全系统闭环仿真。
- 约 533 MB/day 是特定任务占空比下的估算；两轨过站演示不能证明每天都能下传完毕。
- 不把课程工具箱函数、未实现的视觉算法或报告中的概念硬件当作自己已经实现的系统。

新增文档由 AI 辅助整理，依据本地原始材料；没有代替或修改原 assessment。
