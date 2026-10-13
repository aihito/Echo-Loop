# 业务模型字段手册

> 统一结构（类 YAML）。每个字段右侧均有 `#` 中文注释。源码为准。  
> 最后更新：2026-10-12  
> 入口：[学习地图](./README.md)

```yaml
# 每条模型的固定形状：
ModelName:
  file: 相对路径  # 源码位置
  about: 一句话业务含义
  fields:
    fieldName: Type  # 字段业务含义（必有
```

`?` = 可空。标 `runtime: true` 的是运行态，不是材料实体。  
枚举的 `values:` 用 `枚举值: 含义` 表达（含义即注释）。

---

## 0. 共享枚举

```yaml
LearningStage:
  file: lib/database/enums.dart
  about: 学习大阶段（进度指针）
  values:
    firstLearn: 首次学习
    review0: 复习轮 0
    review1: 复习轮 1
    review2: 复习轮 2
    review4: 复习轮 4
    review7: 复习轮 7
    review14: 复习轮 14
    review28: 复习轮 28
    completed: 毕业终态（无子步骤）

SubStageType:
  file: lib/database/enums.dart
  about: 大阶段内的子步骤
  values:
    blindListen: 盲听
    intensiveListen: 逐句精听
    listenAndRepeat: 跟读
    retell: 段落复述
    reviewDifficultPractice: 难句补练
    reviewRetellParagraph: 复习-段落复述
    reviewRetellSummary: 复习-摘要复述（旧 plan）

DifficultyLevel:
  file: lib/database/enums.dart
  about: 材料难度 0–4
  values:
    veryEasy: 0
    easy: 1
    medium: 2
    hard: 3
    veryHard: 4

StudyStage:
  file: lib/models/study_stage.dart
  about: 日统计用的活动类型（≠ LearningStage）
  values:
    blindListen: 全文盲听
    intensiveListen: 逐句精听
    listenAndRepeat: 跟读
    retell: 段落复述
    reviewDifficultPractice: 难句补练
    savedSentencesReview: 收藏句复习
    savedVocabularyReview: 收藏词汇复习
    freePlayer: 随心听

TranscriptSource:
  file: lib/models/audio_item.dart
  about: 字幕从哪来
  values:
    local: 本地文件
    ai: 云端 AI 转录
    device: 设备离线转录

AudioContentStatus:
  file: lib/models/audio_item.dart
  about: 媒体内容健康度（导入时检测）
  values:
    ok: 正常
    damaged: 损坏/无法解码
    silent: 疑似全程静音

MediaType:
  file: lib/models/audio_item.dart
  about: 由扩展名派生，不落库
  values:
    audio: 音频
    video: 视频

AudioImportSourceType:
  file: lib/models/audio_item.dart
  about: 用户导入来源（社区合集不用）
  values:
    local: 本地文件
    directUrl: 直链下载
    cloudDrive: 网盘（预留）

CollectionSource:
  file: lib/models/collection.dart
  about: 合集来源，决定 UI 与同步行为
  values:
    local: 本地自建
    community: 社区合集
    podcast: Podcast 
```

---

## 1. 材料与字幕

```yaml
AudioItem:
  file: lib/models/audio_item.dart
  about: 一条可学习媒体（音频/视频共用；历史命名带 audio）
  fields:
    id: String                                # 本地主键
    name: String                              # 展示名
    audioPath: String?                        # 主媒体相对路径；null=未就绪
    transcriptPath: String?                   # 遗留字幕文件路径；新数据常 null
    addedDate: DateTime                       # 加入时间
    totalDuration: int                        # 时长（秒）
    sentenceCount: int                        # 句数
    wordCount: int                            # 词数
    isPinned: bool                            # 置顶
    transcriptSource: TranscriptSource?       # 非 null 即视为有字幕
    audioSha256: String?                      # 媒体文件指纹
    originalAudioSha256: String?              # 转码前指纹（AI 转录缓存 key）
    transcriptLanguage: String?               # en / multi
    contentStatus: AudioContentStatus?        # 损坏/静音检测
    remoteAudioId: String?                    # 社区后端文件 UUID
    originalDate: DateTime?                   # 社区节目原始播出日
    communityUnavailableAt: DateTime?         # 社区下架时间
    importSourceType: AudioImportSourceType?  # 用户导入类型
    importSourceUrl: String?                  # 直链 URL
    podcastEpisodeGuid: String?               # Podcast 单集 guid
    podcastEnclosureUrl: String?              # enclosure 音频 URL
    podcastEnclosureType: String?             # MIME，如 audio/mpeg
    podcastDescription: String?               # 单集简介
    podcastImageUrl: String?                  # 单集封面
    podcastLink: String?                      # 单集网页链接
  derived:
    mediaType: MediaType                      # 由 audioPath 扩展名派生
    isAudioReady: bool                        # 媒体文件是否已就绪可播
    hasTranscript: bool                       # 是否有字幕（看 transcriptSource）
    isCommunity: bool                         # 是否社区合集材料
    isVideo: bool                             # 是否视频

Sentence:
  file: lib/models/sentence.dart
  about: 一句字幕（时间轴 + 文本）
  fields:
    index: int           # 全局句序
    text: String         # 文本
    startTime: Duration  # 开始时间
    endTime: Duration    # 结束时间
    isBookmarked: bool   # 是否收藏句

WordTimestamp:
  file: lib/models/word_timestamp.dart
  about: 词级时间戳
  fields:
    word: String         # 词文本
    startTime: Duration  # 词开始时间
    endTime: Duration    # 词结束时间

Collection:
  file: lib/models/collection.dart
  about: 合集；成员在 junction 表 collection_audio_items
  fields:
    id: String                         # 本地主键
    name: String                       # 合集名称
    createdDate: DateTime              # 创建时间
    updatedAt: DateTime                # 更新时间
    isPinned: bool                     # 是否置顶
    source: CollectionSource           # 合集来源 local/community/podcast
    remoteId: String?                  # 社区合集后端 UUID
    coverUrl: String?                  # 封面图 URL
    description: String?               # 合集描述
    authorNickname: String?            # 社区作者昵称
    publishedAt: DateTime?             # 社区发布日
    deprecatedAt: DateTime?            # 社区下架时间
    podcastInputUrl: String?           # 用户粘贴的 Apple/RSS URL
    podcastFeedUrl: String?            # 解析后的 Feed URL
    podcastMetaJson: String?           # Feed 元信息 JSON
    podcastLastRefreshedAt: DateTime?  # 上次刷新时间
    podcastLastRefreshError: String?   # 上次刷新错误

Tag:
  file: lib/models/tag.dart
  about: 用户标签
  fields:
    id: String             # 标签主键
    name: String           # 标签名
    colorValue: int        # 颜色整数值
    createdDate: DateTime  # 创建时间

SenseGroupResult:
  file: lib/models/sense_group_result.dart
  about: 一句的意群切分结果
  fields:
    medium: List<String>  # 中等粒度
    fine: List<String>    # 细粒度

MediaLearningStartup:
  file: lib/models/media_learning_startup.dart
  about: 进入媒体练习页的启动参数（不持久化）
  fields:
    loadKey: Object         # 防竞态会话身份
    showVideoLoading: bool  # 显示视频
```

---

## 2. 学习计划与进度

```yaml
LearningPlan:
  file: lib/models/learning_plan.dart
  about: 各大阶段「计划做哪些子步骤」的值对象（按 plan 版本派生）
  fields:
    _stages: Map<LearningStage, List<SubStageType>>  # 内部有序表
  notes:
    - 工厂 LearningPlan.standard(stagePlanVersions)
    - 最新版本表 kLatestPlanVersions
    - firstLearn v1 盲听优先；v2 精听→跟读→盲听→复述

LearningProgress:
  file: lib/models/learning_progress.dart
  about: 单条音频的学习进度（阶段指针、断点、跳过、plan 快照）
  fields:
    audioItemId: String                           # 关联材料 ID
    currentStage: LearningStage                   # 当前大阶段
    currentSubStage: SubStageType                 # 当前子步骤
    difficulty: DifficultyLevel                   # 难度
    firstLearnCompletedAt: DateTime?              # 首次学完（复习基准）
    lastStageCompletedAt: DateTime?               # 上一大阶段完成
    currentStageStartedAt: DateTime?              # 当前阶段开始时间
    totalStudyDurationMs: int                     # 累计学时毫秒
    blindListenPassCount: int                     # 盲听完成遍数
    intensiveListenDifficultCount: int?           # 精听难句数
    intensiveListenPassCount: int?                # 精听遍数
    shadowingPassCount: int?                      # 跟读遍数
    retellPassCount: int?                         # 复述遍数
    blindListenSentenceIndex: int?                # 正式学习断点
    intensiveListenSentenceIndex: int?            # 精听断点句
    shadowingSentenceIndex: int?                  # 跟读断点句
    difficultPracticeSentenceIndex: int?          # 难句补练断点句
    retellSentenceIndex: int?                     # 复述断点句
    freePlayBlindListenSentenceIndex: int?        # 自由练习断点
    freePlayIntensiveListenSentenceIndex: int?    # 自由练习-精听断点
    freePlayShadowingSentenceIndex: int?          # 自由练习-跟读断点
    freePlayDifficultPracticeSentenceIndex: int?  # 自由练习-难句断点
    freePlayRetellSentenceIndex: int?             # 自由练习-复述断点
    newLearningBreakpointSavedAt: DateTime?       # >3 天失效
    freePlayBreakpointSavedAt: DateTime?          # 自由练习断点保存时间
    updatedAt: DateTime                           # 更新时间
    skippedSubStageKeys: Set<String>              # "stage.key:sub.key"
    isPaused: bool                                # 暂停则不参与复习调度
    manualUnlockAt: DateTime?                     # 「立即解锁」当前复习轮
    planVersionsByStage: Map<LearningStage, int>  # 创建时 stamp，日常不改
  derived:
    nextReviewAt: DateTime?                       # 下次可复习时间
    isReviewReady: bool                           # 当前是否已到复习时间
    isReviewLocked: bool                          # 复习是否仍锁定
    firstLearnEntrySubStage: SubStageType         # 首次学习入口子步骤
    progressPercent: double                       # 需配合 plan + completi
```

---

## 3. 收藏、闪卡、记忆调度

```yaml
BookmarkSentence:
  file: lib/models/bookmark_sentence.dart
  about: 带材料来源的收藏句（跨音频复习）
  fields:
    sentence: Sentence          # 句子对象
    audioItemId: String         # 关联材料 ID
    audioName: String           # 来源音频名
    originalSentenceIndex: int  # 原句 index
    memorySubjectId: String     # FSRS 主体 ID

SavedWord:  # Drift 行，无独立 lib/models 类
  file: lib/database/tables/saved_words.dart
  about: 收藏单词（展示文本与调度 ID 解耦）
  fields:
    id: int                     # 自增主键
    word: String                # lemmatized 小写，唯一
    memorySubjectId: String?    # 调度主体 UUID
    audioItemId: String?        # 来源材料
    sentenceIndex: int?         # 来源句 index
    sentenceText: String?       # 冗余语境
    sentenceStartMs: int?       # 来源句起始 ms
    sentenceEndMs: int?         # 来源句结束 ms
    practiceCount: int          # 练习次数
    totalStudyMs: int           # 累计学习 ms
    viewedBack: bool            # 是否翻看过背面
    lastPracticedAt: DateTime?  # 最近练习时间
    createdAt: DateTime         # 创建时间
    updatedAt: DateTime         # 更新时间
    deletedAt: DateTime?        # 软删
    syncStatus: int             # 同步状态（预留）

SavedSenseGroup:
  file: lib/database/tables/saved_sense_groups.dart
  about: 收藏意群/短语
  fields:
    id: int                     # 主键/唯一标识
    phraseText: String          # 归一化，唯一
    memorySubjectId: String?    # 记忆调度主体 ID
    displayText: String         # 展示原文
    audioItemId: String?        # 关联材料 ID
    sentenceIndex: int?         # 来源句 index
    sentenceText: String?       # 来源句文本（冗余）
    sentenceStartMs: int?       # 来源句起始 ms
    sentenceEndMs: int?         # 来源句结束 ms
    groupStartMs: int?          # 意群精确区间
    groupEndMs: int?            # 意群结束 ms
    practiceCount: int          # 练习次数
    totalStudyMs: int           # 累计学习 ms
    viewedBack: bool            # 是否翻看过背面
    lastPracticedAt: DateTime?  # 最近练习时间
    createdAt: DateTime         # 创建时间
    updatedAt: DateTime         # 更新时间
    deletedAt: DateTime?        # 软删除时间
    syncStatus: int             # 同步状态（预留）

FlashcardWordItem:
  file: lib/models/flashcard_item.dart
  about: 单词闪卡
  fields:
    savedWord: SavedWord  # 收藏单词行
    # 内部懒加载 DictEntry

FlashcardPhraseItem:
  file: lib/models/flashcard_item.dart
  about: 意群闪卡
  fields:
    savedPhrase: SavedSenseGroup  # 收藏意群行

MemorySubjectRef:
  file: lib/features/memory_scheduler/domain/memory_subject_ref.dart
  about: 调度绑定的业务主体
  fields:
    namespace: String  # 主体命名空间
    subjectId: String  # 主体 ID

MemoryProfileRef:
  file: lib/features/memory_scheduler/domain/memory_profile.dart
  about: 算法配置引用
  fields:
    profileId: String    # 配置 ID
    profileVersion: int  # 配置版本

MemoryProfile:
  file: lib/features/memory_scheduler/domain/memory_profile.dart
  about: 完整记忆算法配置
  fields:
    ref: MemoryProfileRef             # 配置引用
    modelId: String                   # 算法模型 ID
    parameters: Map<String, Object?>  # 算法参数
    enableFuzzing: bool               # 是否启用到期抖动

MemorySchedule:
  file: lib/features/memory_scheduler/domain/memory_schedule.dart
  about: 某主体的间隔复习调度快照
  fields:
    id: String                        # 主键/唯一标识
    subject: MemorySubjectRef         # 业务主体
    profile: MemoryProfileRef         # 配置引用
    modelId: String                   # 算法模型 ID
    modelStateVersion: int            # 模型状态版本
    phase: MemorySchedulePhase        # newItem|learning|review|relearning
    status: MemoryScheduleStatus      # active|archived
    createdAt: DateTime               # 创建时间
    updatedAt: DateTime               # 更新时间
    lastReviewedAt: DateTime?         # 上次复习时间
    dueAt: DateTime                   # 下次到期
    reviewCount: int                  # 复习次数
    lapseCount: int                   # 遗忘次数
    revision: int                     # 乐观锁
    modelState: Map<String, Object?>  # 算法内部状态
    archivedAt: DateTime?             # 归档时间

MemoryRating:
  file: lib/features/memory_scheduler/domain/memory_rating.dart
  about: 用户回忆质量反馈
  values:
    again: 未能回忆
    hard: 困难
    good: 正常
    easy: 轻松

FavoriteReviewSettings:
  file: lib/models/favorite_review_settings.dart
  about: 收藏复习（综合）偏好
  fields:
    showNextReviewTime: bool     # 显示下次复习时间
    autoPlayFront: bool          # 正面自动播放
    autoPlayBack: bool           # 背面自动播放
    autoShowAiLookup: bool       # 自动 AI 查词
    showVocabularyOnFront: bool  # 正面显示词汇
    order: FavoriteReviewOrder   # smart|dueAt|random

FavoriteVocabularyReviewSettings:
  file: lib/models/favorite_vocabulary_review_settings.dart
  about: 词汇/意群复习偏好
  fields:
    dailyReviewGoal: int?                 # 每日复习目标数
    order: FavoriteVocabularyReviewOrder  # 复习排序策略

BookmarkReviewSettings:
  file: lib/models/bookmark_review_settings.dart
  about: 收藏句复习偏好
  fields:
    showNextReviewTime: bool     # 显示下次复习时间
    dailyReviewGoal: int?        # 每日复习目标数
    order: BookmarkReviewOrder   # 复习排序策略
    autoShowAiExplanation: bool  # 自动显示 AI 讲解
    autoShowAiAnalysis: bool     # 自动显示 AI 解析
    autoShowAiTranslation: bool  # 自动显示 AI 翻译
    autoShowAiSenseGroups: bool  # 自动显
```

---

## 4. AI 与词典

```yaml
SentenceTranslation:
  file: lib/models/sentence_ai_result.dart
  about: 句翻译
  fields:
    translation: String  # 翻译

GrammarPoint:
  file: lib/models/sentence_ai_result.dart
  about: 语法点
  fields:
    point: String  # 要点
    note: String   # 说明

VocabularyItem:
  file: lib/models/sentence_ai_result.dart
  about: 句内词汇讲解
  fields:
    term: String  # 术语
    note: String  # 说明

ListeningPoint:
  file: lib/models/sentence_ai_result.dart
  about: 听力要点
  fields:
    phrase: String  # 短语
    note: String    # 说明

SentenceAnalysis:
  file: lib/models/sentence_ai_result.dart
  about: 句子综合解析
  fields:
    grammar: List<GrammarPoint>       # 语法说明
    vocabulary: List<VocabularyItem>  # 词汇说明
    listening: List<ListeningPoint>   # 听力要点

DictEntry:
  file: lib/models/dict_entry.dart
  about: 本地词典精简条目
  fields:
    word: String            # 词（lemmatized）
    phonetic: String        # 音标
    translation: String?    # 翻译
    collins: int            # 柯林斯星级
    examTags: List<String>  # 考试标签

LocalDictResult:
  file: lib/models/dictionary/dictionary_lookup_result.dart
  about: 查词 → 本地词典
  fields:
    entry: DictEntry  # 词条

AiDictResult:
  file: lib/models/dictionary/dictionary_lookup_result.dart
  about: 查词 → AI 词条
  fields:
    entry: AiDictionaryEntry  # 词条

WebDictResult:
  file: lib/models/dictionary/dictionary_lookup_result.dart
  about: 查词 → 网页词典
  fields:
    sourceId: String  # 词典源 ID
    url: Uri          # 链接
    word: String      # 词（lemmatized）

Pronunciation:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 音标
  fields:
    uk: String  # 百度用户 uk
    us: String  # 美式

ExampleSentence:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 例句
  fields:
    sentence: String     # 句子对象
    translation: String  # 翻译

WordMeaning:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 单词义项
  fields:
    partOfSpeech: String             # 词性
    translation: List<String>        # 翻译
    definition: String               # 英文定义
    usageNote: String                # 用法说明
    examples: List<ExampleSentence>  # 例句列表
    synonyms: List<String>           # 同义词
    antonyms: List<String>           # 反义词

CommonExpression:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 常用表达
  fields:
    expression: String        # 表达/短语
    type: String              # 类型
    meaning: String           # 含义
    example: ExampleSentence  # 例句

WordFamilyItem:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 词族成员
  fields:
    word: String              # 词（lemmatized）
    partOfSpeech: String      # 词性
    meaning: String           # 含义
    example: ExampleSentence  # 例句

WordForm:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 词形变化
  fields:
    form: String   # 词形
    label: String  # 标签文案

DictionaryEntry:
  file: lib/models/dictionary/dictionary_entry.dart
  about: AI 单词词条树
  fields:
    headword: String                           # 中心词
    pronunciation: Pronunciation               # 音标对象
    meanings: List<WordMeaning>                # 义项列表
    commonExpressions: List<CommonExpression>  # 常用表达
    wordFamily: List<WordFamilyItem>           # 词族
    forms: List<WordForm>                      # 词形变化
    etymology: String                          # 词源
    learnerTips: List<String>                  # 学习提示

KeyPoint:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 多词表达要点
  fields:
    point: String        # 要点
    sentence: String     # 句子对象
    translation: String  # 翻译

MultiWordMeaning:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 多词表达义项
  fields:
    translation: List<String>        # 翻译
    examples: List<ExampleSentence>  # 例句列表

SimilarExpression:
  file: lib/models/dictionary/dictionary_entry.dart
  about: 近义表达对比
  fields:
    expression: String   # 表达/短语
    difference: String   # 与近义差异
    sentence: String     # 句子对象
    translation: String  # 翻译

MultiWordDictionaryEntry:
  file: lib/models/dictionary/dictionary_entry.dart
  about: AI 多词/短语词条树
  fields:
    originalExpression: String                   # 原始多词表达
    naturalness: String                          # 自然度评价
    category: String                             # 类别
    pronunciationTips: List<String>              # 发音提示
    keyPoints: List<KeyPoint>                    # 要点列表
    meanings: List<MultiWordMeaning>             # 义项列表
    similarExpressions: List<SimilarExpression>  # 近义表达
    background: String                           # 背景说明

DictionarySettings:
  file: lib/models/dictionary/dictionary_settings.dart
  about: 词典源与行为开关
  fields:
    defaultSourceId: String   # 默认词典源 ID
    disabledIds: Set<String>  # 已禁用词典源
    autoSpeakOnLookup: bool   # 查词自动发音
    adFilteringEnabled: bool  # 网页词典广告过滤

PronunciationClip:
  file: lib/models/pronunciation/pronunciation_clip.dart
  about: 发音库中一条可播放音频
  fields:
    word: String                  # 词（lemmatized）
    locale: String                # 如 en-US
    audioFilename: String         # 音频文件名
    absolutePath: String          # 绝对路径
    reason: PronunciationReason?  # 词性/时态等用途

PronunciationReason:
  file: lib/models/pronunciation/pronunciation_clip.dart
  about: 发音文件用途（文件名后缀解析）
  values:
    adjective: 形容词
    noun: 名词
    nounAdjective: 名形
    verb: 动词
    pastTense: 过去式
    presentTense: 现在式
    interjection: 
```

---

## 5. 跟读、复述、语音

```yaml
SpeechPracticePermissionState:
  file: lib/models/speech_practice_models.dart
  about: 麦克风与语音识别权限
  fields:
    microphone: SpeechPracticePermissionStatus  # 麦克风权限
    speech: SpeechPracticePermissionStatus      # 语音识别权限

SpeechTranscriptSegment:
  file: lib/models/speech_practice_models.dart
  about: 转写/参考文本中的一段对齐结果
  fields:
    text: String     # 文本内容
    isMatched: bool  # 是否匹配

SpeechPracticeEvent:
  file: lib/models/speech_practice_models.dart
  about: 跟读过程事件
  fields:
    type: SpeechPracticeEventType  # 类型
    promptId: String               # 提示句 ID
    transcript: String?            # 转写文本
    errorCode: String?             # 错误码
    errorMessage: String?          # 错误信息
    silenceDuration: Duration?     # 静音时长

SpeechMatchResult:
  file: lib/models/speech_practice_models.dart
  about: 一轮跟读匹配结果
  fields:
    status: SpeechPracticeAttemptStatus                # 状态
    finalTranscript: String                            # 最终转写
    score: double                                      # 得分
    matchedTokenCount: int                             # 匹配 token 数
    totalTargetTokenCount: int                         # 目标 token 总数
    recognizedEnglishTokenCount: int                   # 识别出的英文 token 数
    transcriptSegments: List<SpeechTranscriptSegment>  # 转写分段对齐
    referenceSegments: List<SpeechTranscriptSegment>   # 参考分段对齐

SpeechPracticeAttempt:
  file: lib/models/speech_practice_models.dart
  about: 一次跟读尝试的完整状态
  fields:
    promptId: String                                   # 提示句 ID
    filePath: String?                                  # 文件路径
    status: SpeechPracticeAttemptStatus                # 状态
    liveTranscript: String?                            # 实时转写
    finalTranscript: String?                           # 最终转写
    score: double?                                     # 得分
    matchedTokenCount: int                             # 匹配 token 数
    totalTargetTokenCount: int                         # 目标 token 总数
    transcriptSegments: List<SpeechTranscriptSegment>  # 转写分段对齐
    referenceSegments: List<SpeechTranscriptSegment>   # 参考分段对齐
    errorMessage: String?                              # 错误信息
    hasDetectedSpeech: bool                            # 是否检测到语音
    silenceDuration: Duration                          # 静音时长

SpeechPracticeStopResult:
  file: lib/models/speech_practice_models.dart
  about: 停止录音结果
  fields:
    filePath: String?     # 文件路径
    diagnostics: String?  # 诊断信息

RetellSettings:
  file: lib/models/retell_settings.dart
  about: 复述全局规则
  fields:
    repeatCount: int                        # 重复遍数
    pauseMode: PauseMode                    # 停顿模式
    fixedPauseSeconds: int                  # 固定停顿秒数
    pauseMultiplier: double                 # 相对停顿倍数
    keywordMethod: KeywordMethod            # 关键词提示方式
    keywordRatio: KeywordRatio              # 关键词比例
    controlMode: ShadowingControlMode       # 控制模式（自动/手动等）
    playbackSpeed: double                   # 播放语速
    autoPlayRecordingAfterCompletion: bool  # 完成后自动播录音

RetellReviewKeyPoint:
  file: lib/models/retell_review_evaluation.dart
  about: 复述评价中的要点覆盖
  fields:
    keyPoint: String                     # 要点描述
    original: String                     # 原文摘录
    transcript: String                   # 转写文本
    status: RetellReviewKeyPointStatus?  # 状态
    feedback: String                     # 反馈

RetellReviewCorrection:
  file: lib/models/retell_review_evaluation.dart
  about: 复述纠错项
  fields:
    type: RetellReviewCorrectionType?  # 类型
    transcript: String                 # 转写文本
    correction: String                 # 纠正文本
    explanation: String                # 解释

RetellReviewEvaluation:
  file: lib/models/retell_review_evaluation.dart
  about: 复述 AI 评价整包
  fields:
    transcript: String                         # 转写文本
    summary: String                            # 摘要
    rating: RetellReviewRating?                # poor…perfect
    keyPoints: List<RetellReviewKeyPoint>      # 要点列表
    suggestion: String                         # 建议
    corrections: List<RetellReviewCorrection>  # 纠错列表

RetellReviewStreamFrame:
  file: lib/models/retell_review_evaluation.dart
  about: 流式评价帧
  fields:
    evaluation: RetellReviewEvaluation  # 评价对象
    isFinal: bool                       # 是否最终帧

RatingThresholds:
  file: lib/models/rating_thresholds.dart
  about: 评分分档阈值（跟读 / 复述各有一套常量）
  fields:
    perfect: double    # Perfect 档阈值
    excellent: double  # Excellent 档阈值
    good: double       # Good 档阈值
    fair: double       # Fair 档阈值
  presets:
    listenAndRepeat: {perfect: 0.95, excellent: 0.80, good: 0.60, fair: 0.40}  # 跟读场景默认阈值
    retell: {perfect: 0.90, excellent: 0.75, good: 0.50, fair: 0.20}           # 复述场景阈值（更
```

---

## 6. PDF 导出

```yaml
StudyPdfExportOptions:
  file: lib/models/pdf_export/study_pdf_options.dart
  about: 导出勾选项
  fields:
    includeTranslation: bool  # 导出含翻译
    includeVocabNotes: bool   # 导出含词注
    includeAnalysis: bool     # 导出含解析

StudyPdfGloss:
  file: lib/models/pdf_export/study_pdf_data.dart
  about: 词注义项
  fields:
    pos: String   # 词性
    text: String  # 文本内容

StudyPdfVocabNote:
  file: lib/models/pdf_export/study_pdf_data.dart
  about: 句下词汇注释
  fields:
    number: int                   # 词注编号
    term: String                  # 术语
    phonetic: String              # 音标
    glosses: List<StudyPdfGloss>  # 义项列表

StudyPdfSentence:
  file: lib/models/pdf_export/study_pdf_data.dart
  about: PDF 中的一句
  fields:
    index: int                           # 序号/索引
    text: String                         # 文本内容
    isBookmarked: bool                   # 是否收藏
    translation: String?                 # 翻译
    grammar: String?                     # 语法说明
    vocabulary: String?                  # 词汇说明
    listening: String?                   # 听力要点
    vocabNotes: List<StudyPdfVocabNote>  # 词注列表

StudyPdfDocument:
  file: lib/models/pdf_export/study_pdf_data.dart
  about: 整份学习 PDF
  fields:
    title: String                             # 标题
    paragraphs: List<List<StudyPdfSentence>>  # 段落（句列表的列表）
    durationSeconds: int                      # 时长秒
    wordCount: int                            # 词数

StudyPdfLabels:
  file: lib/models/pdf_export/study_pdf_data.dart
  about: PDF 文案标签（本地化）
  fields:
    metaDuration: String   # 时长标签文案
    metaSentences: String  # 句数标签文案
    metaWords: String      # 词数标签文案
    appendixTitle: String  # 附录标题
    grammar: String        # 语法说明
    vocabulary: String     # 词汇说明
    listening: String      # 听
```

---

## 7. 应用更新

```yaml
AppUpdateInfo:
  file: lib/models/app_update_info.dart
  about: 远程更新描述
  fields:
    latestVersion: String              # 最新版本号
    minimumVersion: String             # 最低强制版本
    releaseNotes: Map<String, String>  # 更新说明（按语言）
    downloadUrl: Map<String, String>   # 下载地址（按平台/语言）
    platforms: AppUpdatePlatforms      # 分平台配置
    channel: AppUpdateChannel          # 更新渠道

IosUpdateConfig:
  file: lib/models/app_update_info.dart
  about: iOS 更新门槛
  fields:
    minimumVersion: String?  # 最低强制版本

AndroidGooglePlayUpdateConfig:
  file: lib/models/app_update_info.dart
  about: Google Play 渠道
  fields:
    minimumVersion: String?  # 最低强制版本
    storeUrl: String?        # 商店页 URL
    fallbackUrl: String?     # 回退 URL

AndroidApkUpdateConfig:
  file: lib/models/app_update_info.dart
  about: APK 直链渠道
  fields:
    latestVersion: String?   # 最新版本号
    minimumVersion: String?  # 最低强制版本
    downloadUrl: String?     # 下载地址（按平台/语言）

AndroidUpdateConfig:
  file: lib/models/app_update_info.dart
  about: Android 双渠道
  fields:
    googlePlay: AndroidGooglePlayUpdateConfig  # Google Play 子配置
    apk: AndroidApkUpdateConfig                # APK 直链子配置

AppUpdatePlatforms:
  file: lib/models/app_update_info.dart
  about: 分平台配置
  fields:
    ios: IosUpdateConfig          # iOS 配置
    android: AndroidUpdateConfig  # Android 配置

AppUpdateResult:
  file: lib/models/app_update_info.dart
  about: 检查更新结果（运行态）
  runtime: true
  fields:
    type: AppUpdateType   # 类型
    info: AppUpdateInfo?  # 更
```

---

## 8. 设置与偏好

```yaml
# Settings = 全局默认；Prefs = 可空覆盖（会话/槽位）

PlaybackSettings:
  file: lib/models/playback_settings.dart
  about: 随心听等通用播放设置
  fields:
    loopWhole: bool             # 是否循环整篇
    wholeLoopCount: int         # 整篇循环次数
    wholeInterval: Duration     # 整篇循环间隔
    loopSentence: bool          # 是否循环单句
    sentenceLoopCount: int      # 单句循环次数
    sentenceInterval: Duration  # 单句循环间隔
    playbackSpeed: double       # 播放语速
    singleSentenceMode: bool    # 单句模式
    showTranscript: bool        # 显示字幕

BlindListenSettings:
  file: lib/models/blind_listen_settings.dart
  about: 盲听全局设置
  fields:
    repeatCount: int                   # 重复遍数
    pauseMode: PauseMode               # 停顿模式
    fixedPauseSeconds: int             # 固定停顿秒数
    pauseMultiplier: double            # 相对停顿倍数
    controlMode: ShadowingControlMode  # 控制模式（自动/手动等）
    playbackSpeed: double              # 播放语速

BlindListenPrefs:
  file: lib/models/blind_listen_prefs.dart  # 实际路径 blind_listen_prefs.dart
  about: 盲听会话覆盖（字段均可空）
  fields:
    playbackSpeed: double?              # 播放语速
    pauseMode: PauseMode?               # 停顿模式
    fixedPauseSeconds: int?             # 固定停顿秒数
    pauseMultiplier: double?            # 相对停顿倍数
    controlMode: ShadowingControlMode?  # 控制模式（自动/手动等）
    repeatCount: int?                   # 重复遍数
    targetSeconds: int?                 # 目标时长秒

IntensiveListenSettings:
  file: lib/models/intensive_listen_settings.dart
  about: 精听全局设置
  fields:
    repeatCount: int                       # 重复遍数
    annotationReplayUsesRepeatCount: bool  # 标注重播是否用重复遍数
    pauseMode: PauseMode                   # 停顿模式
    fixedPauseSeconds: int                 # 固定停顿秒数
    pauseMultiplier: double                # 相对停顿倍数
    controlMode: ShadowingControlMode      # 控制模式（自动/手动等）
    playbackSpeed: double                  # 播放语速

IntensiveListenPrefs:
  file: lib/models/intensive_listen_prefs.dart
  about: 精听会话覆盖
  fields:
    playbackSpeed: double?                       # 播放语速
    pauseMode: PauseMode?                        # 停顿模式
    fixedPauseSeconds: int?                      # 固定停顿秒数
    pauseMultiplier: double?                     # 相对停顿倍数
    controlMode: ShadowingControlMode?           # 控制模式（自动/手动等）
    repeatCount: int?                            # 重复遍数
    annotationReplayUsesRepeatCount: bool?       # 标注重播是否用重复遍数
    listenAndRepeatScope: ListenAndRepeatScope?  # fullText|difficultOnly

DifficultPracticeSettings:
  file: lib/models/difficult_practice_settings.dart
  about: 难句补练全局设置
  fields:
    controlMode: ShadowingControlMode  # 控制模式（自动/手动等）
    blindListenRepeatCount: int        # 盲听遍数
    shadowReadingRepeatCount: int      # 跟读遍数
    pauseMode: PauseMode               # 停顿模式
    fixedPauseSeconds: int             # 固定停顿秒数
    pauseMultiplier: double            # 相对停顿倍数
    playbackSpeed: double              # 播放语速

DifficultPracticePrefs:
  file: lib/models/difficult_practice_prefs.dart
  about: 难句补练会话覆盖（字段均可空，同 Settings 形状）
  fields:
    controlMode: ShadowingControlMode?  # 控制模式（自动/手动等）
    blindListenRepeatCount: int?        # 盲听遍数
    shadowReadingRepeatCount: int?      # 跟读遍数
    pauseMode: PauseMode?               # 停顿模式
    fixedPauseSeconds: int?             # 固定停顿秒数
    pauseMultiplier: double?            # 相对停顿倍数
    playbackSpeed: double?              # 播放语速

RetellPrefs:
  file: lib/models/retell_prefs.dart
  about: 复述会话覆盖
  fields:
    playbackSpeed: double?              # 播放语速
    pauseMode: PauseMode?               # 停顿模式
    fixedPauseSeconds: int?             # 固定停顿秒数
    pauseMultiplier: double?            # 相对停顿倍数
    keywordMethod: KeywordMethod?       # 关键词提示方式
    keywordRatio: KeywordRatio?         # 关键词比例
    controlMode: ShadowingControlMode?  # 控制模式（自动/手动等）
    repeatCount: int?                   # 重复遍数
    targetSeconds: int?                 # 目标时长秒

ReminderSettings:
  file: lib/models/reminder_settings.dart
  about: 复习提醒
  fields:
    savedReviewReminderEnabled: bool  # 收藏复习提醒开关
    savedReviewReminderHour: int      # 提醒小时
    savedReviewReminderMinute: int    # 提醒分钟
    perAudioReminderEnabled: bool     # 按音频提醒开关

SlotPrefs:
  file: lib/models/slot_prefs.dart
  about: 按「子阶段×复习轮」槽位存偏好 P（null=用默认）
  fields:
    _bySlot: Map<String, P>  # 槽位 key → 偏好；缺失=
```

---

## 9. 运行态

```yaml
AudioEngineState:
  file: lib/models/audio_engine_state.dart
  about: 音频引擎瞬时状态
  runtime: true
  fields:
    clipStart: Duration       # 片段起点
    isClipActive: bool        # 是否在播片段
    totalDuration: Duration?  # 总时长（秒）
    isLoading: bool           # 是否加载中
    sessionId: int            # 会话 ID
    currentAudioId: String?   # 当前音频 ID
    errorMessage: String?     # 错误信息

MediaEngineState:
  file: lib/models/media_engine_state.dart
  about: 媒体引擎瞬时状态
  runtime: true
  fields:
    sessionId: int              # 会话 ID
    isLoading: bool             # 是否加载中
    errorMessage: String?       # 错误信息
    currentMediaId: String?     # 当前媒体 ID
    totalDuration: Duration?    # 总时长（秒）
    videoTrackEnabled: bool     # 视频轨开启
    subtitleTrackEnabled: bool  # 字幕轨开启

MediaPlaybackState:
  file: lib/models/media_playback_state.dart
  about: 随心听页会话状态
  runtime: true
  fields:
    audioItem: AudioItem?                     # 当前材料
    sentences: List<Sentence>                 # 句子列表
    currentFullIndex: int?                    # 全文列表当前句
    currentBookmarkIndex: int?                # 收藏列表当前句
    lastPlayedFullIndex: int?                 # 全文上次播放句
    lastPlayedBookmarkIndex: int?             # 收藏上次播放句
    sentenceFocusRevision: int                # 聚焦世代号
    sentenceFocusReason: SentenceFocusReason  # 聚焦原因
    fullSettings: PlaybackSettings            # 全文模式播放设置
    bookmarkSettings: PlaybackSettings        # 收藏模式播放设置
    playlistMode: PlaylistMode                # 播放列表模式
    bookmarkedIndices: Set<int>               # 已收藏句 index 集合
    isLoading: bool                           # 是否加载中
    isTranscriptLoading: bool                 # 字幕加载中
    errorMessage: String?                     # 错误信息
    isPlaying: bool                           # 是否播放中
    wholeLoopsDone: int                       # 整篇已循环次数
    sentenceRepeatsDone: int                  # 单句已重复次数
    position: Duration                        # 当前播放位置
    duration: Duration?                       # 媒体时长
    visualTrackVisible: bool                  # 画面轨可见
    visualTrackExpanded: bool                 # 画面轨展开
    videoSubtitleVisible: bool                # 视频字幕可见
    isLandscapeVideo: bool?                   # 是否横屏视频
    videoAspectRatio: double?                 # 视频宽高比

ListeningPracticeState:
  file: lib/models/listening_practice_state.dart
  about: 听力练习会话（较 MediaPlayback 精简）
  runtime: true
  fields:
    currentAudioItem: AudioItem?        # 当前材料
    sentences: List<Sentence>           # 句子列表
    currentFullIndex: int?              # 全文列表当前句
    currentBookmarkIndex: int?          # 收藏列表当前句
    lastPlayedFullIndex: int?           # 全文上次播放句
    lastPlayedBookmarkIndex: int?       # 收藏上次播放句
    fullSettings: PlaybackSettings      # 全文模式播放设置
    bookmarkSettings: PlaybackSettings  # 收藏模式播放设置
    playlistMode: PlaylistMode          # 播放列表模式
    bookmarkedIndices: Set<int>         # 已收藏句 index 集合
    isLoading: bool                     # 是否加载中
    isPlaying: bool                     # 是否播放中
    wholeLoopsDone: int                 # 整篇已循环次数
    sentenceRepeatsDone: int            # 单句已重复次数

SleepTimerState:
  file: lib/models/sleep_timer_state.dart
  about: 睡眠定时停止（仅内存，不持久化）
  runtime: true
  fields:
    remaining: Duration?  # null=未激活
    presetMinutes: int?   # 当前档位 5/10/15/30/45/60

SenseGroupRangePlayback:
  file: lib/models/sense_group_range_playback.dart
  about: 意群区间播放接口（非数据类）
  runtime: true
  methods:
    play: (audioItemId, start, end) → Future<void>  # 播放意群区间
    cancel: () → Future<void>                       # 取消当前意群播放

SentenceFocusReason:
  file: lib/models/sentence_focus_reason.dart
  about: 句子列表为何聚焦某句（决定动画）
  runtime: true
  values:
    playback: 播放自然推进
    navigation: 用户点句/切句/seek
    immediate: 恢复或返回时无动画定位

SentencePlaybackResult:
  file: lib/models/sentence_playback_result.dart
  about: 单句/区间播放终态
  runtime: true
  values:
    completed: 播到句尾
    cancelled: 被用户或新 session 打断
    failed: 失败/无效

MediaLoadResult:
  file: lib/models/media_load_result.dart
  about: 媒体准备任务终态
  runtime: true
  values:
    ready: 已准备好
    failure: 失败可重试
    cancelled: 被切换/退
```

---

## 10. Feature 模型

```yaml
PodcastFeedMeta:
  file: lib/features/podcast/podcast_models.dart
  about: RSS feed 频道元信息
  fields:
    title: String             # 标题
    author: String?           # 作者
    description: String?      # 描述/简介
    imageUrl: String?         # 封面/图片 URL
    feedUrl: String           # RSS Feed URL
    categories: List<String>  # 分类列表
    language: String?         # 语言
    copyright: String?        # 版权声明
    websiteUrl: String?       # 官网
    explicit: String?         # 是否敏感标记

PodcastEpisode:
  file: lib/features/podcast/podcast_models.dart
  about: RSS 单集（需 enclosure）
  fields:
    guid: String           # RSS guid
    title: String          # 标题
    enclosureUrl: String   # 音频下载 URL
    enclosureType: String  # 音频 MIME
    pubDate: DateTime?     # 发布日期
    durationSeconds: int?  # 时长秒
    description: String?   # 描述/简介
    imageUrl: String?      # 封面/图片 URL
    link: String?          # 网页链接

PodcastFeedResult:
  file: lib/features/podcast/podcast_models.dart
  about: 解析结果
  fields:
    meta: PodcastFeedMeta           # 元信息
    episodes: List<PodcastEpisode>  # 单集列表

PodcastSearchResult:
  file: lib/features/podcast/podcast_models.dart
  about: iTunes 搜索命中
  fields:
    id: String                # 主键/唯一标识
    title: String             # 标题
    author: String?           # 作者
    feedUrl: String           # RSS Feed URL
    artworkUrl: String?       # 封面图
    applePodcastUrl: String?  # Apple Podcasts 链接

PodcastPreviewArg:
  file: lib/features/podcast/podcast_models.dart
  about: 预览页路由参数
  fields:
    title: String             # 标题
    imageUrl: String?         # 封面/图片 URL
    description: String?      # 描述/简介
    author: String?           # 作者
    feedUrl: String?          # RSS Feed URL
    applePodcastUrl: String?  # Apple Podcasts 链接

PodcastCatalogItem:
  file: lib/features/podcast/models/podcast_catalog.dart
  about: 内置播客目录项
  fields:
    id: String               # 主键/唯一标识
    applePodcastUrl: String  # Apple Podcasts 链接
    rssUrl: String           # RSS URL
    imageUrl: String?        # 封面/图片 URL
    title: String            # 标题
    description: String?     # 描述/简介

PodcastCatalogSnapshot:
  file: lib/features/podcast/models/podcast_catalog.dart
  about: 目录快照
  fields:
    podcasts: List<PodcastCatalogItem>  # 播客列表
    contentHash: String                 # 内容哈希
    fetchedAt: DateTime                 # 拉取时间

PublicCollectionCatalogEntry:
  file: lib/features/community_collections/models/community_collection_models.dart
  about: 社区合集列表卡片
  fields:
    id: String               # 主键/唯一标识
    name: String             # 名称
    description: String?     # 描述/简介
    coverUrl: String?        # 封面 URL
    authorNickname: String?  # 作者昵称
    fileCount: int           # 文件数
    publishedAt: DateTime    # 发布时间
    updatedAt: DateTime      # 更新时间

CommunityCollectionFile:
  file: lib/features/community_collections/models/community_collection_models.dart
  about: 社区合集内一个文件
  fields:
    id: String                        # 主键/唯一标识
    title: String                     # 标题
    description: String?              # 描述/简介
    mediaType: CommunityMediaType     # 媒体类型
    durationSec: int?                 # 时长（秒）
    fileSizeBytes: int?               # 文件字节数
    difficulty: CommunityDifficulty?  # 难度
    publishedAt: DateTime?            # 发布时间
    sortOrder: int                    # 排序权重
    mediaUrl: String                  # 媒体下载 URL

CommunitySubtitleSentence:
  file: lib/features/community_collections/models/community_collection_models.dart
  about: 社区下发的一句字幕
  fields:
    text: String         # 文本内容
    startTime: Duration  # 开始时间
    endTime: Duration    # 结束时间

CommunitySubtitle:
  file: lib/features/community_collections/models/community_collection_models.dart
  about: 社区字幕包
  fields:
    sentences: List<CommunitySubtitleSentence>  # 句子列表
    words: List<WordTimestamp>                  # 词级时间戳列表

CommunityCollectionFileDetail:
  file: lib/features/community_collections/models/community_collection_models.dart
  about: 文件详情 = 文件元数据 + 字幕
  fields:
    file: CommunityCollectionFile  # 文件元数据
    subtitle: CommunitySubtitle    # 字幕包

Entitlement:
  file: lib/features/subscription/models/entitlement.dart
  about: 用户会员权益快照
  fields:
    isPremium: bool                  # 是否会员
    activeEntitlements: Set<String>  # 生效权益集合
    productId: String?               # 商品 ID
    period: SubscriptionPeriod?      # 计费周期
    purchaseType: PurchaseType?      # 购买类型
    expiresAt: DateTime?             # 过期时间
    willRenew: bool                  # 是否自动续订
    source: EntitlementSource        # 来源

SubscriptionPlan:
  file: lib/features/subscription/models/subscription_plan.dart
  about: 可购套餐
  fields:
    planId: String                       # 套餐 ID
    title: String                        # 标题
    priceString: String                  # 价格展示串
    period: SubscriptionPeriod           # 计费周期
    purchaseType: PurchaseType           # 购买类型
    hasFreeTrial: bool                   # 是否含试用
    trialDays: int                       # 试用天数
    introOffer: SubscriptionIntroOffer?  # 首购/试用优惠

SubscriptionIntroOffer:
  file: lib/features/subscription/models/subscription_plan.dart
  about: 首购/试用优惠
  fields:
    priceString: String              # 价格展示串
    period: SubscriptionOfferPeriod  # 计费周期
    periodNumberOfUnits: int         # 优惠周期单位数
    cycles: int                      # 优惠循环次数
    isFreeTrial: bool                # 是否免费试用
    renewalPriceString: String       # 续费价格展示

ChatMessage:
  file: lib/features/chatbot/models/chat_message.dart
  about: 对话一条消息
  fields:
    id: String                           # 主键/唯一标识
    role: ChatRole                       # 角色
    content: String                      # 内容
    status: ChatMessageStatus            # streaming|done|error|quotaBlocked|authRequired
    quotaReason: AiQuotaRejectionReason  # 额度拒绝原因
    createdAt: DateTime                  # 创建时间
    includeInHistory: bool               # 是否纳入发给后端的历史
    quote: String?                       # 引用原文

ChatbotConfig:
  file: lib/features/chatbot/models/chatbot_config.dart
  about: 同一套 Chatbot 在不同入口的可插拔配置
  fields:
    sessionId: String              # family 身份键，如 sentence:$hash
    endpoint: String               # 后端 path（不同 prompt）
    context: Map<String, Object?>  # 请求体业务上下文
    title: String                  # 载体标题
    inputPlaceholder: String       # 输入框占位
    greeting: String?              # 开场白（不入历史发后端）
    contextSummary: String?        # 上下文 chip 文案

AiQuotaRejection:
  file: lib/features/subscription/models/ai_quota_rejection.dart
  about: AI 额度拒绝信息（402）
  fields:
    reason: AiQuotaRejectionReason  # exhausted | unsupportedForFreePlan
    resetAt: DateTime?              # 额度重置时间

PremiumFeature:
  file: lib/features/subscription/models/premium_feature.dart
  about: 付费墙保护的 AI 能力（核心学习闭环免费）
  values:
    aiTranslation: 句翻译
    aiAnalysis: 句解析
    aiSenseGroup: 意群切分
    aiWordAnalysis: 词深解
    aiTranscription: AI 转录
    aiChat: 对话助手
    aiRetellReview: 复述评估

EntitlementSource:
  file: lib/features/subscription/models/entitlement_source.dart
  about: 权益购买来源（与当前运行平台解耦）
  values:
    apple: App Store
    google: Google Play
    paddle: Paddle
    unknown: 未知/老缓存

OnboardingAnswers:
  file: lib/features/onboarding_survey/models/onboarding_answers.dart
  about: 首启问卷答案草稿/终稿
  fields:
    goal: String?            # OnboardingGoal 编码
    examType: String?        # goal=exam 时必填
    goalOtherText: String?   # 旧版兼容，新 UI 不写
    dailyMinutes: String?    # 5|10|20|30|flexible
    referralSource: String?  # 渠道编码

OnboardingOption:
  file: lib/features/onboarding_survey/models/onboarding_question.dart
  about: 问卷选项元数据
  fields:
    code: String      # 持久化/埋点编码
    labelKey: String  # ARB 文案 key

BaiduAccountProfile:
  file: lib/features/baidu_netdisk/models/baidu_account_profile.dart
  about: 百度网盘账号资料
  fields:
    uk: int               # 百度用户 uk
    baiduName: String?    # 百度账号名
    netdiskName: String?  # 网盘昵称
    vipType: int?         # 会员类型
    avatarUrl: String?    # 头像 URL

BaiduCredentialBundle:
  file: lib/features/baidu_netdisk/models/baidu_credential_bundle.dart
  about: OAuth 令牌包
  fields:
    accessToken: String   # 访问令牌
    refreshToken: String  # 刷新令牌
    expiresAt: DateTime   # 过期时间
    scope: String         # OAuth scope

BaiduOAuthSession:
  file: lib/features/baidu_netdisk/models/baidu_oauth_session.dart
  about: 授权会话（打开授权页 + 轮询）
  fields:
    sessionId: String       # 会话 ID
    pollToken: String       # 轮询令牌
    authorizationUri: Uri   # 授权页 URI
    expiresAt: DateTime     # 过期时间
    pollInterval: Duration  # 轮询间隔

BaiduOAuthSessionStatus:
  file: lib/features/baidu_netdisk/models/baidu_oauth_session_status.dart
  about: 授权会话当前阶段
  fields:
    phase: BaiduOAuthSessionPhase       # 阶段
    credential: BaiduCredentialBundle?  # 令牌包
    error: BaiduNetdiskApiError?        # 错误对象

BaiduNetdiskApiError:
  file: lib/features/baidu_netdisk/models/baidu_netdisk_error.dart
  about: 网盘 API/OAuth 错误
  fields:
    code: BaiduNetdiskOAuthErrorCode  # 稳定编码
    message: String                   # 消息/错误文案

CloudDriveEntry:
  file: lib/features/baidu_netdisk/models/cloud_drive_models.dart
  about: 网盘文件/目录项
  fields:
    fsId: int              # 网盘文件 ID
    name: String           # 名称
    path: String           # 路径
    isDirectory: bool      # 是否文件夹
    size: int              # 大小（字节）
    modifiedAt: DateTime?  # 修改时间

CloudDriveListPage:
  file: lib/features/baidu_netdisk/models/cloud_drive_models.dart
  about: 网盘列表分页
  fields:
    entries: List<CloudDriveEntry>  # 条目列表
    nextStart: int                  # 下一页起始游标
    hasMore: bool                   # 是否还有更多

CloudDriveImportItemResult:
  file: lib/features/baidu_netdisk/models/cloud_drive_models.dart
  about: 单文件导入结果
  fields:
    entry: CloudDriveEntry              # 词条
    status: CloudDriveImportItemStatus  # 状态
    item: AudioItem?                    # 导入成功的 AudioItem
    duplicateExistingName: String?      # 重复项已有名称
    failure: CloudDriveImportFailure?   # 失败详情

CloudDriveImportOutcome:
  file: lib/features/baidu_netdisk/models/cloud_drive_models.dart
  about: 一批导入总结果
  fields:
    added: List<CloudDriveEntry>             # 成功加入的网盘项
    addedItems: List<AudioItem>              # 成功加入的 AudioItem
    duplicateDetails: List                   # AudioImportDuplicate
    duplicateEntries: List<CloudDriveEntry>  # 重复的网盘项
    failures: List<CloudDriveImportFailure>  # 失败列表
    wasCanceled: bool                        # 用户是否取消

CloudDriveImportFailure:
  file: lib/features/baidu_netdisk/models/cloud_drive_models.dart
  about: 导入失败项
  fields:
    entry: CloudDriveEntry  # 词条
    message: String         # 消息/错误文案
    errorKind: String       # 错误种类

BaiduDownloadLink:
  file: lib/features/baidu_netdisk/models/cloud_drive_models.dart
  about: 直链下载信息
  fields:
    fsId: int      # 网盘文件 ID
    dlink: String  # 直链地址
    size: int?     # 大小（字节）
    name: String?  # 文件名
```

---

## 与数据库（核心）

```yaml
persistence_map:
  AudioItem: audio_items                                # 材料主表
  Collection: collections                               # 合集主表；成员在 collection_audio_items
  LearningProgress: learning_progress 相关表             # 进度指针 / 断点 / plan 快照等
  completions: stage_completions                        # 子步骤真实完成记录
  SavedWord: saved_words                                # 收藏单词表
  SavedSenseGroup: saved_sense_groups                   # 收藏意群表
  MemorySchedule: memory_schedules                      # 间隔复习调度表
  podcast_fields: collections.* / audio_items.podcast*  # Podcast 字段落在合集与材料列
```

---

## 维护

改模型字段 → 同步改本节对应 YAML 块。形状保持：`name` / `file` / `about` / `fields`（一行一个字段，`#` 注释列对齐）。
