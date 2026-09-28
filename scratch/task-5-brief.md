# Task 5 Brief: AI 提示词多语言动态指令联动

**File:**
- Modify: `Floreboard/Core/Services/AIProxyClient.swift`

**Requirements:**
1. 在 `buildSystemPrompt(language: Language, request: DesignRequest, inventory: [FlowerType]) -> String` 中：
   - 适配全部 5 种语言（`.zh`, `.en`, `.ja`, `.ko`, `.fr`）
   - 针对每种语言配置专有的语言名称 `langName` 与强化指令 `langRule`：
     - `.zh`: `langName = "Simplified Chinese (简体中文)"`, `langRule = "所有文本（标题 title、设计理念 description、花语寓意 meaningText、制作步骤 steps、选花理由 reason）必须全部使用规范的简体中文输出。"`
     - `.en`: `langName = "English"`, `langRule = "All text fields (title, description, meaningText, steps, reason) must be written in fluent, elegant English."`
     - `.ja`: `langName = "Japanese (日本語)"`, `langRule = "すべてのテキスト（タイトル title、コンセプト説明 description、花言葉 meaningText、制作手順 steps、選定理由 reason）を必ず自然で洗練された日本語で出力してください。"`
     - `.ko`: `langName = "Korean (한국어)"`, `langRule = "모든 텍스트(제목 title, 디자인 설명 description, 꽃말/의미 meaningText, 제작 단계 steps, 선택 이유 reason)를 반드시 자연스럽고 품격 있는 한국어로 출력하십시오."`
     - `.fr`: `langName = "French (Français)"`, `langRule = "Tous les champs textuels (title, description, meaningText, steps, reason) doivent être rédigés en français élégant et naturel."`
   - 在专业版（`request.designMode == "professional"`）与普通版提示词模板中统一注入：
     ```
     CRITICAL MULTILINGUAL INSTRUCTION:
     Output Language: \(langName)
     \(langRule)
     Keep imagePrompt strictly in English for high-fidelity diffusion rendering.
     Keep flowerName strictly matching the available inventory names.
     ```
2. 验证：
   - 运行 `xcodebuild -scheme Floreboard -destination 'generic/platform=iOS Simulator' -derivedDataPath ./build/DerivedData build`
   - 确保无编译报错。
3. 提交：
   - `git add Floreboard/Core/Services/AIProxyClient.swift`
   - `git commit -m "feat(ai): add 5-language dynamic prompt instructions for floral design generation"`
4. 输出报告至 `scratch/task-5-report.md`。
