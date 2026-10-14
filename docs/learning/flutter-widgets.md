# Flutter 常用组件参考

> 查阅手册：按名称或场景找到控件 → 看清职责与参数 → 对照最小示例使用。  
> 收录条目均为统一深写体例（无浅写表）。不含与其它 UI 框架的对照。  
> 以 Flutter SDK / [api.flutter.dev](https://api.flutter.dev/) 为准。  
> 最后更新：2026-10-14 · 入口：[学习地图](./README.md)

**条目体例**

| 块 | 含义 |
|----|------|
| 作用 | 一句话职责 |
| 适用 / 不适用 | 何时选用、何时换别的 |
| 常用参数 | 实际会改的 API |
| 最小示例 | 可粘贴到页面中的短代码 |
| 注意 | 约束、父级、易错点 |
| 官方 | API 文档入口 |

**怎么用**：§1 按名跳转 → 读参数与示例 → 对照 §2 排查布局问题 → 需要时打开官方链接。

---

## 目录

1. [索引（按名称）](#1-索引按名称)
2. [布局与约束速查](#2-布局与约束速查)
3. [页面与布局](#3-页面与布局)
4. [层叠、显隐与切换](#4-层叠显隐与切换)
5. [滚动与列表](#5-滚动与列表)
6. [展示与输入](#6-展示与输入)
7. [手势与按钮](#7-手势与按钮)
8. [反馈与面板](#8-反馈与面板)
9. [主题、视口与导航](#9-主题视口与导航)
10. [工具型组件](#10-工具型组件)
11. [选型速查](#11-选型速查)
12. [本仓库对照（附录）](#12-本仓库对照附录)
13. [建议查阅路径](#13-建议查阅路径)

---

## 1. 索引（按名称）

| 名称 | 位置 |
|------|------|
| `AbsorbPointer` | [§10.6](#106-ignorepointer--absorbpointer) |
| `AlertDialog` / `showDialog` | [§8.1](#81-showdialog--alertdialog) |
| `Align` | [§3.9](#39-align--center) |
| `AppBar` | [§3.8](#38-appbar) |
| `AspectRatio` | [§3.11](#311-aspectratio--fractionallysizedbox) |
| `Builder` | [§10.1](#101-builder) |
| `Card` | [§6.7](#67-card) |
| `Center` | [§3.9](#39-align--center) |
| `Checkbox` / `CheckboxListTile` | [§6.8](#68-checkbox--radio--switch) |
| `CircleAvatar` | [§6.6](#66-circleavatar) |
| `CircularProgressIndicator` | [§8.4](#84-circularprogressindicator--linearprogressindicator) |
| `Column` | [§3.2](#32-row--column) |
| `Container` | [§3.6](#36-container--sizedbox--padding) |
| `CustomScrollView` | [§5.5](#55-customscrollview--sliverappbar) |
| `Divider` | [§6.12](#612-divider) |
| `Drawer` | [§9.7](#97-drawer) |
| `DropdownMenu` | [§6.10](#610-dropdownmenu) |
| `ElevatedButton` / `FilledButton` 等 | [§7.3](#73-按钮族) |
| `Expanded` / `Flexible` | [§3.3](#33-expanded--flexible) |
| `FittedBox` | [§3.12](#312-fittedbox) |
| `FloatingActionButton` | [§7.3](#73-按钮族) |
| `Form` | [§6.4](#64-form) |
| `FractionallySizedBox` | [§3.11](#311-aspectratio--fractionallysizedbox) |
| `FutureBuilder` | [§10.4](#104-futurebuilder--streambuilder) |
| `GestureDetector` | [§7.1](#71-gesturedetector) |
| `GridView` | [§5.3](#53-gridview) |
| `Hero` | [§8.6](#86-hero) |
| `Icon` | [§6.5](#65-icon--image) |
| `IconButton` | [§7.3](#73-按钮族) |
| `IgnorePointer` | [§10.6](#106-ignorepointer--absorbpointer) |
| `Image` | [§6.5](#65-icon--image) |
| `IndexedStack` | [§4.2](#42-indexedstack) |
| `InkWell` | [§7.2](#72-inkwell) |
| `Key` / `KeyedSubtree` | [§10.7](#107-key--keyedsubtree) |
| `LinearProgressIndicator` | [§8.4](#84-circularprogressindicator--linearprogressindicator) |
| `ListTile` | [§6.3](#63-listtile) |
| `ListView` | [§5.2](#52-listview--listviewbuilder) |
| `MaterialApp` | [§9.4](#94-materialapp) |
| `MediaQuery` | [§9.2](#92-mediaqueryofcontext) |
| `NavigationBar` | [§9.3](#93-navigationbar) |
| `NavigationRail` | [§9.5](#95-navigationrail) |
| `Offstage` / `Opacity` / `Visibility` | [§4.3](#43-offstage--visibility--opacity) |
| `Padding` | [§3.6](#36-container--sizedbox--padding) |
| `PageView` | [§5.4](#54-pageview) |
| `PopScope` | [§9.8](#98-popscope) |
| `PopupMenuButton` | [§8.7](#87-popupmenubutton) |
| `Positioned` | [§3.10](#310-positioned) |
| `Radio` / `RadioListTile` | [§6.8](#68-checkbox--radio--switch) |
| `RefreshIndicator` | [§5.6](#56-refreshindicator) |
| `RepaintBoundary` | [§10.5](#105-repaintboundary) |
| `Row` | [§3.2](#32-row--column) |
| `SafeArea` | [§3.7](#37-safearea) |
| `Scaffold` | [§3.1](#31-scaffold) |
| `SegmentedButton` | [§6.9](#69-segmentedbutton) |
| `showModalBottomSheet` | [§8.2](#82-showmodalbottomsheet) |
| `SingleChildScrollView` | [§5.1](#51-singlechildscrollview) |
| `SizedBox` | [§3.6](#36-container--sizedbox--padding) |
| `Slider` / `RangeSlider` | [§6.11](#611-slider--rangeslider) |
| `SliverAppBar` | [§5.5](#55-customscrollview--sliverappbar) |
| `SnackBar` | [§8.3](#83-snackbar) |
| `Spacer` | [§3.5](#35-spacer) |
| `Stack` | [§4.1](#41-stack) |
| `StatefulBuilder` | [§10.2](#102-statefulbuilder) |
| `StreamBuilder` | [§10.4](#104-futurebuilder--streambuilder) |
| `Switch` / `SwitchListTile` | [§6.8](#68-checkbox--radio--switch) |
| `TabBar` / `TabBarView` | [§9.6](#96-tabbar--tabbarview) |
| `Text` | [§6.1](#61-text) |
| `TextField` / `TextFormField` | [§6.2](#62-textfield--textformfield) |
| `Theme` | [§9.1](#91-themeofcontext) |
| `Tooltip` | [§8.5](#85-tooltip) |
| `ValueListenableBuilder` | [§10.3](#103-valuelistenablebuilder) |
| `Wrap` | [§3.4](#34-wrap) |

---

## 2. 布局与约束速查

Flutter 布局核心：**父级下发约束（min/max 宽高），子级在约束内选择尺寸并回报。**

| 现象 | 常见原因 | 处理方向 |
|------|----------|----------|
| 黄黑条纹溢出 | 子级在主轴上需要的尺寸超过父级 max | `Expanded`/`Flexible`、缩小内容、外包滚动 |
| `Vertical viewport was given unbounded height` | `ListView` 等拿到主轴无界高度 | 外包 `Expanded` / 固定高度；慎用 `shrinkWrap` |
| `Expanded` 断言失败 | 不是 `Row`/`Column`/`Flex` 的直接子级 | 调整树结构 |
| Ink 涟漪不可见 | 无 `Material` 祖先，或不透明层遮挡 | 外包 `Material`，检查叠层 |
| 键盘挡住输入 | 未使用 `Scaffold` 调整或未处理 `viewInsets` | `resizeToAvoidBottomInset`；或读 `MediaQuery.viewInsetsOf` |

```text
Column( children: [
  Text('固定'),
  Expanded(child: ListView(...)),  // OK：ListView 获得有界高度
])

Column( children: [
  ListView(...),  // 错误：高度无界
])
```

---

## 3. 页面与布局

### 3.1 Scaffold

**作用**：Material 页面结构槽位（顶栏、正文、底栏、FAB、抽屉等）。

**适用**：绝大多数 Screen 根节点。  
**不适用**：无意义的嵌套 Scaffold；极简浮层不一定需要。

**常用参数**：`appBar`、`body`、`floatingActionButton`、`bottomNavigationBar`、`drawer`/`endDrawer`、`resizeToAvoidBottomInset`、`backgroundColor`。

```dart
Scaffold(
  appBar: AppBar(title: const Text('标题')),
  body: const Center(child: Text('内容')),
  floatingActionButton: FloatingActionButton(
    onPressed: () {},
    child: const Icon(Icons.add),
  ),
)
```

**注意**：`SnackBar` 依赖 `ScaffoldMessenger`；全屏子路由各自带 `Scaffold` 属正常。

**官方**：[Scaffold](https://api.flutter.dev/flutter/material/Scaffold-class.html)

---

### 3.2 Row / Column

**作用**：沿水平 / 垂直主轴排列子组件（Flex）。

**适用**：工具条、表单纵排、标题与按钮并排。  
**不适用**：需换行 → `Wrap`；长列表 → `ListView`。

**常用参数**：`mainAxisAlignment`、`crossAxisAlignment`、`mainAxisSize`（`max`/`min`）、`children`。

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    const Text('标题'),
    const SizedBox(height: 8),
    Row(
      children: [
        const Icon(Icons.star),
        const SizedBox(width: 8),
        const Expanded(child: Text('占满剩余宽度', overflow: TextOverflow.ellipsis)),
        TextButton(onPressed: () {}, child: const Text('操作')),
      ],
    ),
  ],
)
```

**注意**：主轴不足会溢出；用 `Expanded`/`Flexible` 或滚动解决。

**官方**：[Row](https://api.flutter.dev/flutter/widgets/Row-class.html) · [Column](https://api.flutter.dev/flutter/widgets/Column-class.html)

---

### 3.3 Expanded / Flexible

**作用**：在 Flex 父级内按 `flex` 分配剩余主轴空间。

**适用**：一侧固定一侧撑满；多项按比例分割。  
**不适用**：父级非 Flex；流式换行用 `Wrap`。

**常用参数**：`flex`（默认 1）、`fit`（仅 `Flexible`：`tight`/`loose`）、`child`。  
`Expanded` ≡ `Flexible(fit: FlexFit.tight)`。

```dart
Row(
  children: [
    const Icon(Icons.menu),
    const Expanded(child: Text('中间自适应', overflow: TextOverflow.ellipsis)),
    IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
  ],
)
```

**注意**：必须是 Flex 的**直接**子级。

**官方**：[Expanded](https://api.flutter.dev/flutter/widgets/Expanded-class.html) · [Flexible](https://api.flutter.dev/flutter/widgets/Flexible-class.html)

---

### 3.4 Wrap

**作用**：沿主轴排布；当前 run 空间不足时换到下一 run。

**适用**：Chip、标签、数量不定的横排控件。  
**不适用**：单行均分剩余空间 → `Row`+`Expanded`；大数据 → 列表/网格。

**常用参数**：`direction`、`spacing`、`runSpacing`、`alignment`、`runAlignment`、`children`。

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final label in ['精听', '跟读', '盲听', '复述'])
      Chip(label: Text(label)),
  ],
)
```

**注意**：单个子项过宽仍可能在 run 内溢出。

**官方**：[Wrap](https://api.flutter.dev/flutter/widgets/Wrap-class.html)

---

### 3.5 Spacer

**作用**：在 Flex 主轴插入可伸缩空白。

**适用**：两端子项顶到两端。  
**不适用**：非 Flex 父级。

```dart
Row(children: const [Text('左'), Spacer(), Text('右')])
```

**注意**：等价于无 child 的 `Expanded`。

**官方**：[Spacer](https://api.flutter.dev/flutter/widgets/Spacer-class.html)

---

### 3.6 Container / SizedBox / Padding

**作用**

| Widget | 作用 |
|--------|------|
| `SizedBox` | 固定宽高或间距 |
| `Padding` | 仅内边距 |
| `Container` | 尺寸 + 边距 + 对齐 + `decoration` |

**适用**：`Container` 用于背景/圆角/阴影；只需边距用 `Padding`；只需尺寸用 `SizedBox`。  
**不适用**：用 `Container` 堆叠无意义装饰。

```dart
const SizedBox(height: 16);

Padding(
  padding: const EdgeInsets.all(16),
  child: const Text('内容'),
);

Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  ),
  child: const Text('卡片内容'),
)
```

**注意**：不可同时设 `Container.color` 与 `decoration`；颜色放入 `BoxDecoration.color`。

**官方**：[Container](https://api.flutter.dev/flutter/widgets/Container-class.html) · [SizedBox](https://api.flutter.dev/flutter/widgets/SizedBox-class.html) · [Padding](https://api.flutter.dev/flutter/widgets/Padding-class.html)

---

### 3.7 SafeArea

**作用**：按 `MediaQuery` 避开系统遮挡区（状态栏、刘海、手势条等）。

**适用**：自定义贴边 UI、自定义底栏。  
**不适用**：在已处理安全区的 `Scaffold.body` 上重复层层包裹（通常多余）。

**常用参数**：`top`/`bottom`/`left`/`right`、`minimum`、`child`。

```dart
SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: /* 自定义底栏 */,
  ),
)
```

**官方**：[SafeArea](https://api.flutter.dev/flutter/widgets/SafeArea-class.html)

---

### 3.8 AppBar

**作用**：页面顶栏，用作 `Scaffold.appBar`。

**适用**：标题、返回、操作。  
**不适用**：随列表折叠 → `SliverAppBar`。

**常用参数**：`title`、`leading`、`actions`、`bottom`、`centerTitle`、`automaticallyImplyLeading`。

```dart
AppBar(
  title: const Text('学习计划'),
  actions: [
    IconButton(
      onPressed: () {},
      icon: const Icon(Icons.more_vert),
      tooltip: '更多',
    ),
  ],
)
```

**注意**：操作逻辑放在页面 / notifier，勿把重业务塞进 `AppBar`。

**官方**：[AppBar](https://api.flutter.dev/flutter/material/AppBar-class.html)

---

### 3.9 Align / Center

**作用**：按对齐方式（`Center` = 居中）在父级内放置子组件。

**适用**：空状态、加载指示、局部对齐。  
**不适用**：Stack 内贴边定位 → 优先 `Positioned`。

**常用参数**：`alignment`（`Align`）、`widthFactor`/`heightFactor`、`child`。

```dart
const Center(child: CircularProgressIndicator());

Align(
  alignment: Alignment.topRight,
  child: const Icon(Icons.close),
)
```

**官方**：[Align](https://api.flutter.dev/flutter/widgets/Align-class.html) · [Center](https://api.flutter.dev/flutter/widgets/Center-class.html)

---

### 3.10 Positioned

**作用**：在 `Stack` 内按边距定位子项。

**适用**：角标、浮层按钮。  
**不适用**：非 `Stack` 父级（会断言失败）。

**常用参数**：`left`/`top`/`right`/`bottom`、`width`/`height`、`child`。

```dart
Stack(
  children: [
    const ColoredBox(color: Colors.grey, child: SizedBox.expand()),
    Positioned(
      right: 8,
      bottom: 8,
      child: IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow)),
    ),
  ],
)
```

**注意**：相对对边同时指定时可拉伸子项。

**官方**：[Positioned](https://api.flutter.dev/flutter/widgets/Positioned-class.html)

---

### 3.11 AspectRatio / FractionallySizedBox

**作用**

| Widget | 作用 |
|--------|------|
| `AspectRatio` | 强制子项区域符合宽高比 |
| `FractionallySizedBox` | 相对父级宽/高的比例尺寸 |

**适用**：封面 16:9；宽度占父级 80%。  
**不适用**：已由图片 `fit` 足够表达时再叠无意义比例。

```dart
AspectRatio(
  aspectRatio: 16 / 9,
  child: Image.network('https://example.com/a.jpg', fit: BoxFit.cover),
)

FractionallySizedBox(
  widthFactor: 0.8,
  child: const LinearProgressIndicator(value: 0.4),
)
```

**官方**：[AspectRatio](https://api.flutter.dev/flutter/widgets/AspectRatio-class.html) · [FractionallySizedBox](https://api.flutter.dev/flutter/widgets/FractionallySizedBox-class.html)

---

### 3.12 FittedBox

**作用**：缩放并定位子组件以适应约束。

**适用**：过大子项塞进有限区域。  
**不适用**：正文排版（优先 `Text` 的 `overflow`/`maxLines`）。

**常用参数**：`fit`（`BoxFit`）、`alignment`、`child`。

```dart
SizedBox(
  width: 40,
  height: 40,
  child: FittedBox(
    child: const Icon(Icons.home, size: 80),
  ),
)
```

**注意**：位图缩放可能模糊。

**官方**：[FittedBox](https://api.flutter.dev/flutter/widgets/FittedBox-class.html)

---

## 4. 层叠、显隐与切换

### 4.1 Stack

**作用**：按声明顺序叠放（后者在上）。

**适用**：媒体叠加控件、多层宿主。  
**不适用**：多页切换保状态 → `IndexedStack`。

**常用参数**：`alignment`、`fit`、`clipBehavior`、`children`。

```dart
SizedBox(
  height: 160,
  width: double.infinity,
  child: Stack(
    fit: StackFit.expand,
    children: [
      Image.network('https://example.com/cover.jpg', fit: BoxFit.cover),
      const Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.play_circle, size: 48, color: Colors.white),
        ),
      ),
    ],
  ),
)
```

**官方**：[Stack](https://api.flutter.dev/flutter/widgets/Stack-class.html)

---

### 4.2 IndexedStack

**作用**：挂载全部子树，仅展示 `index` 项；切换保留 `State`。

**适用**：自定义 Tab、保留滚动/表单。  
**不适用**：需卸载不可见页释放资源 → 条件构建或路由分支。

**常用参数**：`index`、`children`、`sizing`、`alignment`。

```dart
IndexedStack(
  index: currentIndex,
  children: const [
    Center(child: Text('视图 A')),
    Center(child: Text('视图 B')),
  ],
)
```

**注意**：不可见子树仍占用资源。

**官方**：[IndexedStack](https://api.flutter.dev/flutter/widgets/IndexedStack-class.html)

---

### 4.3 Offstage / Visibility / Opacity

**作用**

| Widget | 作用 |
|--------|------|
| `Offstage` | 不布局、不绘制；子树可仍挂载 |
| `Visibility` | 控制可见与是否占位 |
| `Opacity` | 透明度；默认可参与布局与命中 |

**适用**：条件显隐、淡入淡出。  
**不适用**：需释放资源时仅隐藏不卸载。

```dart
Offstage(offstage: hidden, child: const HeavyWidget());

Visibility(
  visible: showBanner,
  maintainState: true,
  child: const Banner(),
);

Opacity(opacity: 0.5, child: const Text('半透明'))
```

**注意**：长期隐藏的重子树应条件构建（`if`）而非永久 `Offstage`。

**官方**：[Offstage](https://api.flutter.dev/flutter/widgets/Offstage-class.html) · [Visibility](https://api.flutter.dev/flutter/widgets/Visibility-class.html) · [Opacity](https://api.flutter.dev/flutter/widgets/Opacity-class.html)

---

## 5. 滚动与列表

### 5.1 SingleChildScrollView

**作用**：使单一子树在约束不足时可滚动。

**适用**：设置页、短表单。  
**不适用**：大量重复项 → `ListView.builder`。

**常用参数**：`scrollDirection`、`controller`、`padding`、`physics`、`child`。

```dart
SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [for (var i = 0; i < 20; i++) Text('行 $i')],
  ),
)
```

**注意**：勿与无界 `ListView` 同轴嵌套；见 §2。

**官方**：[SingleChildScrollView](https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html)

---

### 5.2 ListView / ListView.builder

**作用**：一维列表；`builder` 懒构建可见项。

**适用**：合集、消息、设置列表。  
**不适用**：少量固定块 → `Column` + `SingleChildScrollView`。

**常用参数**：`itemCount`、`itemBuilder`、`controller`、`padding`、`shrinkWrap`、`physics`、`separatorBuilder`（`separated`）。

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    final item = items[index];
    return ListTile(title: Text(item.title), onTap: () {});
  },
)
```

**注意**：在 `Column` 内须获得有界高度（如外包 `Expanded`）。

**官方**：[ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html)

---

### 5.3 GridView

**作用**：二维网格滚动列表。

**适用**：封面墙、缩略图。  
**不适用**：一维设置列表 → `ListView`。

**常用参数**：`gridDelegate`（如 `SliverGridDelegateWithFixedCrossAxisCount`）、`children` 或 `itemBuilder`、`padding`。

```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1,
  ),
  itemCount: covers.length,
  itemBuilder: (context, index) => Image.network(covers[index], fit: BoxFit.cover),
)
```

**注意**：同样需要有界视口约束。

**官方**：[GridView](https://api.flutter.dev/flutter/widgets/GridView-class.html)

---

### 5.4 PageView

**作用**：可分页视口（常水平滑动）。

**适用**：引导页、整页翻页。  
**不适用**：长列表浏览 → `ListView`。

**常用参数**：`controller`（`PageController`）、`onPageChanged`、`children` / `itemBuilder`、`scrollDirection`。

```dart
PageView(
  onPageChanged: (i) {},
  children: const [
    Center(child: Text('第 1 页')),
    Center(child: Text('第 2 页')),
  ],
)
```

**注意**：用 `PageController` 可 `animateToPage`；记得 `dispose` controller。

**官方**：[PageView](https://api.flutter.dev/flutter/widgets/PageView-class.html)

---

### 5.5 CustomScrollView / SliverAppBar

**作用**：将多个 Sliver 组合为同一滚动视图；`SliverAppBar` 可折叠/钉住。

**适用**：折叠顶栏 + 列表。  
**不适用**：简单单列表（直接 `ListView` 更简单）。

**常用参数**：`slivers`；`SliverAppBar` 的 `pinned`/`floating`/`expandedHeight`/`flexibleSpace`。

```dart
CustomScrollView(
  slivers: [
    const SliverAppBar(
      pinned: true,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(title: Text('标题')),
    ),
    SliverList.builder(
      itemCount: 30,
      itemBuilder: (context, index) => ListTile(title: Text('项 $index')),
    ),
  ],
)
```

**注意**：列表须用 `SliverList`/`SliverGrid`，不要在 `slivers` 里直接塞普通 `ListView`。

**官方**：[CustomScrollView](https://api.flutter.dev/flutter/widgets/CustomScrollView-class.html) · [SliverAppBar](https://api.flutter.dev/flutter/material/SliverAppBar-class.html)

---

### 5.6 RefreshIndicator

**作用**：下拉刷新；`onRefresh` 返回 `Future`。

**适用**：列表刷新。  
**不适用**：非滚动子树（需要可滚动 child）。

```dart
RefreshIndicator(
  onRefresh: () async {
    await loadData();
  },
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ListTile(title: Text(items[index])),
  ),
)
```

**注意**：子级必须可滚动且内容足以产生 overscroll；内容过短可设 `physics: AlwaysScrollableScrollPhysics()`。

**官方**：[RefreshIndicator](https://api.flutter.dev/flutter/material/RefreshIndicator-class.html)

---

## 6. 展示与输入

### 6.1 Text

**作用**：渲染文本。

**适用**：标题、正文。  
**不适用**：复杂可选中业务选区 → 专用组件；多风格片段 → `Text.rich`。

**常用参数**：`style`、`textAlign`、`maxLines`、`overflow`、`softWrap`。

```dart
Text(
  '合集名称',
  style: Theme.of(context).textTheme.titleMedium,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
)
```

**注意**：样式优先取自 `textTheme`。

**官方**：[Text](https://api.flutter.dev/flutter/widgets/Text-class.html)

---

### 6.2 TextField / TextFormField

**作用**：文本输入；`TextFormField` 可参与 `Form` 校验。

**适用**：搜索、命名、登录。  
**不适用**：富文本编辑器场景。

**常用参数**：`controller`、`focusNode`、`decoration`、`obscureText`、`keyboardType`、`maxLines`、`onChanged`、`onSubmitted`、`validator`（FormField）。

```dart
TextField(
  controller: controller,
  decoration: const InputDecoration(
    labelText: '合集名称',
    border: OutlineInputBorder(),
  ),
)
```

**注意**：在 `State` 中创建的 `controller`/`focusNode` 须 `dispose`。

**官方**：[TextField](https://api.flutter.dev/flutter/material/TextField-class.html) · [TextFormField](https://api.flutter.dev/flutter/material/TextFormField-class.html)

---

### 6.3 ListTile

**作用**：标准列表行（leading / title / subtitle / trailing）。

**适用**：设置项、合集行。  
**不适用**：高度定制行 → 自建布局。

**常用参数**：`leading`、`title`、`subtitle`、`trailing`、`onTap`、`selected`、`enabled`。

```dart
ListTile(
  leading: const Icon(Icons.folder),
  title: const Text('我的合集'),
  subtitle: const Text('12 条音频'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {},
)
```

**官方**：[ListTile](https://api.flutter.dev/flutter/material/ListTile-class.html)

---

### 6.4 Form

**作用**：统一子 `FormField` 的 `validate` / `save`。

**适用**：多字段提交前校验。  
**不适用**：单框即时搜索。

```dart
final formKey = GlobalKey<FormState>();

Form(
  key: formKey,
  child: Column(
    children: [
      TextFormField(
        decoration: const InputDecoration(labelText: '名称'),
        validator: (v) => (v == null || v.trim().isEmpty) ? '不能为空' : null,
      ),
      FilledButton(
        onPressed: () {
          if (formKey.currentState?.validate() ?? false) { /* 提交 */ }
        },
        child: const Text('保存'),
      ),
    ],
  ),
)
```

**注意**：普通 `TextField` 不参与 `Form` 校验。

**官方**：[Form](https://api.flutter.dev/flutter/widgets/Form-class.html)

---

### 6.5 Icon / Image

**作用**：图标字体 / 图像显示。

**适用**：按钮图标、封面、插图。  
**不适用**：矢量插画复杂场景可能需 `SvgPicture` 等包。

**常用参数（Icon）**：`Icons.xxx`、`size`、`color`。  
**常用参数（Image）**：`Image.asset`/`network`/`file`、`fit`、`width`/`height`、`errorBuilder`。

```dart
const Icon(Icons.settings, size: 24);

Image.network(
  url,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stack) => const Icon(Icons.broken_image),
)
```

**注意**：网络图务必处理失败与占位；资源图路径须在 `pubspec.yaml` 声明。

**官方**：[Icon](https://api.flutter.dev/flutter/widgets/Icon-class.html) · [Image](https://api.flutter.dev/flutter/widgets/Image-class.html)

---

### 6.6 CircleAvatar

**作用**：圆形头像容器。

**适用**：用户/作者头像。  
**不适用**：任意圆角矩形 → `ClipRRect`。

**常用参数**：`radius`、`backgroundImage`、`backgroundColor`、`child`。

```dart
CircleAvatar(
  radius: 24,
  backgroundImage: NetworkImage(url),
  child: url.isEmpty ? const Icon(Icons.person) : null,
)
```

**官方**：[CircleAvatar](https://api.flutter.dev/flutter/material/CircleAvatar-class.html)

---

### 6.7 Card

**作用**：带 Material 阴影/圆角的内容容器。

**适用**：内容分组卡片。  
**不适用**：只需色块 → `ColoredBox`/`DecoratedBox`。

**常用参数**：`elevation`、`color`、`shape`、`margin`、`child`、`clipBehavior`。

```dart
Card(
  child: ListTile(
    title: const Text('标题'),
    subtitle: const Text('说明'),
    onTap: () {},
  ),
)
```

**官方**：[Card](https://api.flutter.dev/flutter/material/Card-class.html)

---

### 6.8 Checkbox / Radio / Switch

**作用**：多选 / 互斥单选 / 布尔开关。`*ListTile` 变体带标题行。

**适用**：协议勾选、选项组、设置开关。  
**不适用**：多选项胶囊切换 → 可考虑 `SegmentedButton`。

```dart
CheckboxListTile(
  value: agreed,
  onChanged: (v) => setState(() => agreed = v ?? false),
  title: const Text('同意条款'),
);

// 同一 groupValue 下互斥
Column(
  children: [
    RadioListTile<String>(
      title: const Text('选项 A'),
      value: 'a',
      groupValue: selected,
      onChanged: (v) => setState(() => selected = v),
    ),
    RadioListTile<String>(
      title: const Text('选项 B'),
      value: 'b',
      groupValue: selected,
      onChanged: (v) => setState(() => selected = v),
    ),
  ],
);

SwitchListTile(
  value: enabled,
  onChanged: (v) => setState(() => enabled = v),
  title: const Text('启用通知'),
)
```

**注意**：`onChanged: null` 表示禁用；Radio 必须共享同一 `groupValue`。

**官方**：[Checkbox](https://api.flutter.dev/flutter/material/Checkbox-class.html) · [Radio](https://api.flutter.dev/flutter/material/Radio-class.html) · [Switch](https://api.flutter.dev/flutter/material/Switch-class.html)

---

### 6.9 SegmentedButton

**作用**：分段单选或多选。

**适用**：视图模式、筛选。  
**不适用**：导航顶级目的地 → `NavigationBar`。

**常用参数**：`segments`、`selected`、`onSelectionChanged`、`multiSelectionEnabled`。

```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'a', label: Text('合集')),
    ButtonSegment(value: 'b', label: Text('音频')),
  ],
  selected: {mode},
  onSelectionChanged: (set) => setState(() => mode = set.first),
)
```

**官方**：[SegmentedButton](https://api.flutter.dev/flutter/material/SegmentedButton-class.html)

---

### 6.10 DropdownMenu

**作用**：Material 3 下拉选择（录入或点选）。

**适用**：排序、语言等枚举选择。  
**不适用**：超长异步列表（考虑独立选择页）。

**常用参数**：`dropdownMenuEntries`、`initialSelection`、`onSelected`、`label`、`controller`。

```dart
DropdownMenu<String>(
  initialSelection: 'dateDesc',
  label: const Text('排序'),
  dropdownMenuEntries: const [
    DropdownMenuEntry(value: 'dateDesc', label: '最新'),
    DropdownMenuEntry(value: 'nameAsc', label: '名称'),
  ],
  onSelected: (v) {},
)
```

**注意**：旧代码常见 `DropdownButton`；新界面优先 `DropdownMenu`。

**官方**：[DropdownMenu](https://api.flutter.dev/flutter/material/DropdownMenu-class.html)

---

### 6.11 Slider / RangeSlider

**作用**：在连续区间选择单值或范围。

**适用**：语速、音量阈值。  
**不适用**：离散枚举 → `SegmentedButton`/`DropdownMenu`。

**常用参数**：`value`/`values`、`min`/`max`、`divisions`、`label`、`onChanged`。

```dart
Slider(
  value: speed,
  min: 0.5,
  max: 2.0,
  divisions: 6,
  label: speed.toStringAsFixed(1),
  onChanged: (v) => setState(() => speed = v),
)
```

**官方**：[Slider](https://api.flutter.dev/flutter/material/Slider-class.html) · [RangeSlider](https://api.flutter.dev/flutter/material/RangeSlider-class.html)

---

### 6.12 Divider

**作用**：水平 / 垂直分割线（`VerticalDivider`）。

**适用**：列表或栏内视觉分隔。  
**不适用**：大块留白（用 `SizedBox`）。

**常用参数**：`height`、`thickness`、`indent`、`endIndent`、`color`。

```dart
const Divider(height: 1)
```

**官方**：[Divider](https://api.flutter.dev/flutter/material/Divider-class.html)

---

## 7. 手势与按钮

### 7.1 GestureDetector

**作用**：绑定手势，无 Material ink splash。

**适用**：自定义区域、拖拽。  
**不适用**：要标准涟漪 → `InkWell`；标准按钮外观 → 按钮族。

**常用参数**：`onTap`、`onLongPress`、`onPanUpdate`、`behavior`、`child`。

```dart
GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: () {},
  child: const Padding(
    padding: EdgeInsets.all(12),
    child: Text('可点击区域'),
  ),
)
```

**官方**：[GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)

---

### 7.2 InkWell

**作用**：手势 + Material ink splash。

**适用**：自定义卡片/行点击。  
**不适用**：无 splash 需求。

```dart
Material(
  color: Colors.transparent,
  child: InkWell(
    onTap: () {},
    borderRadius: BorderRadius.circular(8),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('带涟漪的点击'),
    ),
  ),
)
```

**注意**：需 `Material` 祖先。

**官方**：[InkWell](https://api.flutter.dev/flutter/material/InkWell-class.html)

---

### 7.3 按钮族

**作用**：预置 Material 按钮。

| Widget | 用途 |
|--------|------|
| `FilledButton` / `ElevatedButton` | 主要操作 |
| `OutlinedButton` | 次要操作 |
| `TextButton` | 三级 / 对话框取消 |
| `IconButton` | 工具栏图标 |
| `FloatingActionButton` | 页级主创建 |

**常用参数**：`onPressed`（`null`=禁用）、`child`/`icon`、`style`、`tooltip`（IconButton）。

```dart
FilledButton(onPressed: () {}, child: const Text('创建'));
IconButton(onPressed: () {}, icon: const Icon(Icons.settings), tooltip: '设置');
```

**官方**：[FilledButton](https://api.flutter.dev/flutter/material/FilledButton-class.html)

---

## 8. 反馈与面板

### 8.1 showDialog / AlertDialog

**作用**：模态对话框。

**适用**：确认、警告。  
**不适用**：复杂多步 → 路由页或 sheet。

```dart
await showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('删除？'),
    content: const Text('不可撤销。'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
      FilledButton(onPressed: () => Navigator.pop(context), child: const Text('删除')),
    ],
  ),
);
```

**官方**：[showDialog](https://api.flutter.dev/flutter/material/showDialog.html) · [AlertDialog](https://api.flutter.dev/flutter/material/AlertDialog-class.html)

---

### 8.2 showModalBottomSheet

**作用**：底部模态面板。

**适用**：操作菜单、短表单。  
**不适用**：完整导航栈长流程。

```dart
await showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(title: const Text('选项 A'), onTap: () => Navigator.pop(context)),
      ],
    ),
  ),
);
```

**常用参数**：`isScrollControlled`、`showDragHandle`、`builder`。

**官方**：[showModalBottomSheet](https://api.flutter.dev/flutter/material/showModalBottomSheet.html)

---

### 8.3 SnackBar

**作用**：短时底部提示。

**适用**：成功/轻量错误。  
**不适用**：必须确认的错误。

```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('已保存')),
);
```

**官方**：[SnackBar](https://api.flutter.dev/flutter/material/SnackBar-class.html)

---

### 8.4 CircularProgressIndicator / LinearProgressIndicator

**作用**：环形 / 线性进度（可确定或不确定）。

**适用**：加载、下载进度。  
**不适用**：整页阻塞且无文案（宜配合说明文字）。

```dart
const CircularProgressIndicator();
LinearProgressIndicator(value: progress); // 0.0–1.0；null 为不确定
```

**官方**：[CircularProgressIndicator](https://api.flutter.dev/flutter/material/CircularProgressIndicator-class.html)

---

### 8.5 Tooltip

**作用**：长按或悬停时显示说明。

**适用**：图标按钮含义（桌面尤重要）。  
**不适用**：替代正文说明。

```dart
Tooltip(
  message: '设置',
  child: IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
)
```

**官方**：[Tooltip](https://api.flutter.dev/flutter/material/Tooltip-class.html)

---

### 8.6 Hero

**作用**：路由过渡中的共享元素动画。

**适用**：列表缩略图到详情大图。  
**不适用**：无路由过渡的局部动画。

```dart
Hero(
  tag: 'cover-$id',
  child: Image.network(url, fit: BoxFit.cover),
)
// 详情页使用相同 tag
```

**注意**：交互双方 `tag` 必须唯一且一致。

**官方**：[Hero](https://api.flutter.dev/flutter/widgets/Hero-class.html)

---

### 8.7 PopupMenuButton

**作用**：点击弹出菜单。

**适用**：列表「更多」操作。  
**不适用**：底部多选项 → sheet 可能更合适。

```dart
PopupMenuButton<String>(
  onSelected: (value) {},
  itemBuilder: (context) => const [
    PopupMenuItem(value: 'edit', child: Text('编辑')),
    PopupMenuItem(value: 'delete', child: Text('删除')),
  ],
)
```

**官方**：[PopupMenuButton](https://api.flutter.dev/flutter/material/PopupMenuButton-class.html)

---

## 9. 主题、视口与导航

### 9.1 Theme.of(context)

**作用**：读取 `ThemeData`。

**适用**：颜色、字号、组件主题。  
**不适用**：魔法数色值散落业务。

```dart
final scheme = Theme.of(context).colorScheme;
Text('标题', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: scheme.primary));
```

**注意**：登记依赖；主题变更会重建。

**官方**：[Theme](https://api.flutter.dev/flutter/material/Theme-class.html)

---

### 9.2 MediaQuery.of(context)

**作用**：读取视口与设备指标。

**适用**：断点、键盘 inset、文字缩放。  
**不适用**：可用 Flex 解决的简单居中。

```dart
final width = MediaQuery.sizeOf(context).width;
final keyboard = MediaQuery.viewInsetsOf(context).bottom;
```

**注意**：优先 `sizeOf` / `viewInsetsOf` 等细分 API。

**官方**：[MediaQuery](https://api.flutter.dev/flutter/widgets/MediaQuery-class.html)

---

### 9.3 NavigationBar

**作用**：Material 3 底部导航。

**适用**：移动端主壳 3～5 入口。  
**不适用**：宽屏侧栏 → `NavigationRail`。

```dart
NavigationBar(
  selectedIndex: index,
  onDestinationSelected: (i) {},
  destinations: const [
    NavigationDestination(icon: Icon(Icons.library_books), label: '资源库'),
    NavigationDestination(icon: Icon(Icons.school), label: '学习'),
  ],
)
```

**官方**：[NavigationBar](https://api.flutter.dev/flutter/material/NavigationBar-class.html)

---

### 9.4 MaterialApp

**作用**：应用根：主题、本地化、路由等。

**适用**：`main` 配置一次。  
**不适用**：业务页再套一层。

**常用参数**：`theme`/`darkTheme`/`themeMode`、`locale`、`supportedLocales`、`localizationsDelegates`、`home` 或 `routerConfig`。

```dart
MaterialApp.router(
  theme: ThemeData(colorSchemeSeed: Colors.teal),
  routerConfig: router,
)
```

**官方**：[MaterialApp](https://api.flutter.dev/flutter/material/MaterialApp-class.html)

---

### 9.5 NavigationRail

**作用**：侧向导航栏（常用于宽屏）。

**适用**：桌面/平板主壳。  
**不适用**：手机底栏场景。

**常用参数**：`selectedIndex`、`onDestinationSelected`、`destinations`、`labelType`、`extended`。

```dart
NavigationRail(
  selectedIndex: index,
  onDestinationSelected: (i) {},
  labelType: NavigationRailLabelType.all,
  destinations: const [
    NavigationRailDestination(icon: Icon(Icons.home), label: Text('首页')),
    NavigationRailDestination(icon: Icon(Icons.settings), label: Text('设置')),
  ],
)
```

**官方**：[NavigationRail](https://api.flutter.dev/flutter/material/NavigationRail-class.html)

---

### 9.6 TabBar / TabBarView

**作用**：标签与内容页联动。

**适用**：页内二级分类。  
**不适用**：App 顶级 Tab（多用壳导航）。

**常用参数**：需 `TabController` 或外包 `DefaultTabController`；`tabs`、`children` 数量一致。

```dart
DefaultTabController(
  length: 2,
  child: Column(
    children: const [
      TabBar(tabs: [Tab(text: 'A'), Tab(text: 'B')]),
      Expanded(child: TabBarView(children: [Center(child: Text('A')), Center(child: Text('B'))])),
    ],
  ),
)
```

**注意**：自管 `TabController` 时须绑定 `TickerProvider` 并 `dispose`。

**官方**：[TabBar](https://api.flutter.dev/flutter/material/TabBar-class.html) · [TabBarView](https://api.flutter.dev/flutter/material/TabBarView-class.html)

---

### 9.7 Drawer

**作用**：侧滑抽屉，作 `Scaffold.drawer`。

**适用**：次级导航、账号入口。  
**不适用**：主路径的仅有导航（优先底栏/侧栏）。

```dart
Scaffold(
  drawer: Drawer(
    child: ListView(
      children: [
        const DrawerHeader(child: Text('菜单')),
        ListTile(title: const Text('设置'), onTap: () {}),
      ],
    ),
  ),
  body: /* ... */,
)
```

**官方**：[Drawer](https://api.flutter.dev/flutter/material/Drawer-class.html)

---

### 9.8 PopScope

**作用**：观察或拦截系统返回（取代已弃用的 `WillPopScope`）。

**适用**：未保存确认。  
**不适用**：普通页无条件返回。

```dart
PopScope(
  canPop: !hasUnsavedChanges,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    final leave = await confirmDiscard(context);
    if (leave && context.mounted) Navigator.of(context).pop();
  },
  child: /* 编辑页 */,
)
```

**注意**：API 随 SDK 略有演进，以当前 Flutter 文档为准。

**官方**：[PopScope](https://api.flutter.dev/flutter/widgets/PopScope-class.html)

---

## 10. 工具型组件

### 10.1 Builder

**作用**：提供新的 `BuildContext`。

**适用**：在同一 `build` 中需要「子级 context」以查找外侧 `ScaffoldMessenger` 等。  
**不适用**：无必要地加深树。

```dart
Builder(
  builder: (context) {
    return TextButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ok')),
        );
      },
      child: const Text('提示'),
    );
  },
)
```

**官方**：[Builder](https://api.flutter.dev/flutter/widgets/Builder-class.html)

---

### 10.2 StatefulBuilder

**作用**：在 builder 内提供局部 `setState`（常见于对话框）。

**适用**：弹窗内开关/计数。  
**不适用**：页面级状态（用 `State` 或状态管理）。

```dart
showDialog(
  context: context,
  builder: (context) {
    var checked = false;
    return StatefulBuilder(
      builder: (context, setLocal) {
        return AlertDialog(
          content: CheckboxListTile(
            value: checked,
            onChanged: (v) => setLocal(() => checked = v ?? false),
            title: const Text('选项'),
          ),
        );
      },
    );
  },
);
```

**官方**：[StatefulBuilder](https://api.flutter.dev/flutter/widgets/StatefulBuilder-class.html)

---

### 10.3 ValueListenableBuilder

**作用**：监听 `ValueListenable`（如 `ValueNotifier`）并重建。

**适用**：轻量局部状态。  
**不适用**：跨页复杂业务（本仓库多用 Riverpod）。

```dart
final counter = ValueNotifier(0);

ValueListenableBuilder<int>(
  valueListenable: counter,
  builder: (context, value, child) => Text('$value'),
)
```

**注意**：记得处置 `ValueNotifier`。

**官方**：[ValueListenableBuilder](https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html)

---

### 10.4 FutureBuilder / StreamBuilder

**作用**：根据 `Future`/`Stream` 快照构建 UI。

**适用**：简单一次性请求或事件流。  
**不适用**：复杂业务生命周期（易陷入乱序与重复请求；优选用状态管理）。

```dart
FutureBuilder<String>(
  future: fetchTitle(),
  builder: (context, snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const CircularProgressIndicator();
    }
    if (snapshot.hasError) return Text('错误: ${snapshot.error}');
    return Text(snapshot.data ?? '');
  },
)
```

**注意**：勿在 `build` 里每次新建 `Future`（会重复请求）；将 future 存入 State 或上层。

**官方**：[FutureBuilder](https://api.flutter.dev/flutter/widgets/FutureBuilder-class.html) · [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html)

---

### 10.5 RepaintBoundary

**作用**：隔离重绘边界，减少无关区域重绘。

**适用**：性能热点（复杂动画旁的静态区域）。  
**不适用**：过早优化、到处包裹。

```dart
RepaintBoundary(child: const ExpensiveChart())
```

**官方**：[RepaintBoundary](https://api.flutter.dev/flutter/widgets/RepaintBoundary-class.html)

---

### 10.6 IgnorePointer / AbsorbPointer

**作用**：忽略或吸收指针事件（子树不可点）。

**适用**：加载遮罩下禁用操作。  
**区别**：`IgnorePointer` 事件可穿透到下层；`AbsorbPointer` 吸收事件不传下层。

```dart
Stack(
  children: [
    content,
    if (loading)
      const AbsorbPointer(
        child: ColoredBox(
          color: Color(0x66000000),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
  ],
)
```

**官方**：[IgnorePointer](https://api.flutter.dev/flutter/widgets/IgnorePointer-class.html) · [AbsorbPointer](https://api.flutter.dev/flutter/widgets/AbsorbPointer-class.html)

---

### 10.7 Key / KeyedSubtree

**作用**：标识 Element 身份，影响复用与状态保留。

**适用**：强制重置子树、列表项稳定身份（`ValueKey`/`ObjectKey`）。  
**不适用**：无意义地给每个 Widget 加 Key。

```dart
TextField(key: ValueKey(resetToken)); // token 变则重建，清空内部状态

KeyedSubtree(
  key: ValueKey(sessionId),
  child: const EditorPanel(),
)
```

**官方**：[Key](https://api.flutter.dev/flutter/foundation/Key-class.html)

---

## 11. 选型速查

| 需求 | 优先选择 |
|------|----------|
| 标准页面 | `Scaffold` + `AppBar` |
| 横 / 竖排列 | `Row` / `Column` |
| 剩余空间 | `Expanded` |
| 换行流式 | `Wrap` |
| 间距 / 固定尺寸 | `SizedBox` / `Padding` |
| 装饰块 | `Container` 或 `Card` |
| 居中 / 对齐 | `Center` / `Align` |
| 叠层定位 | `Stack` + `Positioned` |
| 切换保 State | `IndexedStack` |
| 长列表 / 网格 | `ListView.builder` / `GridView` |
| 分页滑动 | `PageView` |
| 折叠顶栏 | `CustomScrollView` + `SliverAppBar` |
| 下拉刷新 | `RefreshIndicator` |
| 文本 / 输入 | `Text` / `TextField` |
| 表单校验 | `Form` + `TextFormField` |
| 列表行 | `ListTile` |
| 开关 / 勾选 | `SwitchListTile` / `CheckboxListTile` |
| 标准按钮 | `FilledButton` 等 |
| 自定义点击 | `InkWell` 或 `GestureDetector` |
| 对话框 / 底栏 | `showDialog` / `showModalBottomSheet` |
| 短提示 | `SnackBar` |
| 主题 / 屏宽 | `Theme.of` / `MediaQuery.sizeOf` |
| 底栏 / 侧栏导航 | `NavigationBar` / `NavigationRail` |
| 拦截返回 | `PopScope` |

---

## 12. 本仓库对照（附录）

| 概念 | 位置 |
|------|------|
| `Scaffold` 页面 | `lib/screens/*_screen.dart` |
| `IndexedStack` | `lib/screens/library_screen.dart` |
| `NavigationBar` / `NavigationRail` | `lib/router/main_shell.dart` 等 |
| Bottom sheet | `lib/widgets/*_sheet.dart` |
| 主题 | `lib/theme/app_theme.dart` |
| 业务封装（非本文） | `lib/widgets/`、`lib/features/*/widgets/` |

---

## 13. 建议查阅路径

| 目标 | 路径 |
|------|------|
| 选型 | [§11](#11-选型速查) → 对应深写节 |
| 按名查找 | [§1](#1-索引按名称) |
| 溢出 / 无界约束 | [§2](#2-布局与约束速查) |
| 学会用法 | 参数 → 示例 → 注意 → 官方链接 |
| 对照 App | [§12](#12-本仓库对照附录) |

练习：每学一个控件，先跑通最小示例，再在仓库搜索同名用法。

---

## 维护

- 新增控件必须按六块体例写入，并同步 §1 索引与 §11 选型。  
- 不再维护「浅写表」；确属极冷门 API 可只给官方链接条目，但仍需作用/适用/注意。  
- Material 弃用/更名时同步正文与官方链接。  
- 不收录跨框架对照；业务封装不进正文。
