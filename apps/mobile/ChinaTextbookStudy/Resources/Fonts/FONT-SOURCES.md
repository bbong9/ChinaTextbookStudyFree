# 字体来源与许可

核验日期：2026-10-20。两套字体均以 SIL Open Font License 1.1 分发；全文保存在同目录 `OFL-ZCOOL-KuaiLe.txt`、`OFL-Nunito.txt`，随 App 一起打包。

- ZCOOL KuaiLe：Google Fonts 官方仓库 `google/fonts/ofl/zcoolkuaile/ZCOOLKuaiLe-Regular.ttf`，原始文件未修改，未做子集化。
- Nunito：Google Fonts 官方仓库 `google/fonts/ofl/nunito/Nunito[wght].ttf`，使用 fonttools 4.67.0 提取 wght=800/900 两个静态实例，并更新 name 表（PostScript 名称为 Nunito-ExtraBold / Nunito-Black）。OFL 允许此修改和随应用分发，原版权和许可证均保留。
- 官方来源：https://github.com/google/fonts/tree/main/ofl/zcoolkuaile 、https://github.com/google/fonts/tree/main/ofl/nunito
- 楷体由 iOS 系统字体服务按需下载，不附带第三方楷体文件。

重现 Nunito 实例：

```sh
fonttools varLib.instancer 'Nunito[wght].ttf' wght=800 --update-name-table -o Nunito-ExtraBold.ttf
fonttools varLib.instancer 'Nunito[wght].ttf' wght=900 --update-name-table -o Nunito-Black.ttf
```

| 文件 | 字节数 | SHA-256 |
| --- | ---: | --- |
| Nunito-Black.ttf | 132,164 | `2522b39c9261bc026198343a5765937b9c372f72cc617b6e39b5195d667277e8` |
| Nunito-ExtraBold.ttf | 132,224 | `0b022885a998fdac304deefcf2ba47185df3e76c62b56c6cce86db8e03a31b01` |
| ZCOOLKuaiLe-Regular.ttf | 1,514,968 | `812a6fc1fe54b6d73a419245c32dfeba8aa33104d5be90d1cf6af082007cb71d` |

字体文件总计 **1,779,356 字节（1.697 MiB）**，小于 8 MiB。此处为未压缩资源增量；不冒充 IPA 压缩后增量。
