# イシュー: 証明債務の解消 (Progressive Proof Fulfillment)

## 概要
コードベースに残存する概念的な証明 (`sorry`) を、Lean カーネルが検証可能な完全な数学的証明へと置き換える。

## 詳細タスク
- [ ] `MainLoop.lean`: 状態遷移におけるリスト長の増減を利用した、Well-founded recursion によるループ停止性の完全証明。
- [ ] `Memory/TokenManager.lean`: リスト境界を越えない安全な切り詰め処理の証明。
- [ ] `Core/Sanitizer.lean`: 文字列操作が長さを増大させないことの証明。
