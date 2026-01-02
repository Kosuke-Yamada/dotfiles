# Serena Dashboard

Serena のウェブダッシュボードをブラウザで開きます。

以下のコマンドを実行してください：

```bash
open http://localhost:24282/dashboard/
```

ダッシュボードが開けない場合は、ポート番号が異なる可能性があります。
以下のコマンドでポートを確認できます：

```bash
lsof -i :24282-24290 | grep LISTEN
```
