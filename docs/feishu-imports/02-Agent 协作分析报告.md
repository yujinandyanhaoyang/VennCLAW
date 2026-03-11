# Agent 协作分析报告

**工程路径**: /root/WORK/SCHOOL/ACPs-app  
**分析时间**: 2026-03-10 08:12 GMT+8  
**基于任务**: task-20260310-002-P2  

---

## Agent 列表

| Agent 名称 | 路径 | 主要职责 | 输入 | 输出 |
|-----------|------|---------|------|------|
| ReaderProfile | agents/reader_profile_agent/ | 用户画像构建 | user_profile, history, reviews | preference_vector, sentiment_summary |
| BookContent | agents/book_content_agent/ | 书籍内容分析 | books, candidate_ids, query | content_vectors, book_tags, kg_refs |
| RecRanking | agents/rec_ranking_agent/ | 推荐排序决策 | profile_vector, candidates, constraints | ranking, explanations, metrics |
| ReadingConcierge | reading_concierge/ | 编排协调器 (Leader) | query, user_profile, history | 完整推荐结果 + 评估指标 |

---

## 依赖关系

```mermaid
graph TD
    RC[ReadingConcierge<br/>编排协调器] --> RP[ReaderProfile<br/>用户画像 Agent]
    RC --> BC[BookContent<br/>书籍内容 Agent]
    RP --> RR[RecRanking<br/>推荐排序 Agent]
    BC --> RR
    RR --> RC
    
    subgraph 并行阶段
        RP
        BC
    end
    
    subgraph 串行阶段
        RR
    end
```

---

## 交互流程

```mermaid
sequenceDiagram
    participant User as 用户
    participant RC as ReadingConcierge
    participant RP as ReaderProfile
    participant BC as BookContent
    participant RR as RecRanking
    
    User->>RC: POST /user_api (query + profile)
    
    RC->>RC: 场景识别 (cold/warm/explore)
    RC->>RC: 策略配置 (权重 + 约束)
    
    par 并行调用
        RC->>RP: RPC /reader-profile/rpc<br/>payload: {user_profile, history, reviews}
        RC->>BC: RPC /book-content/rpc<br/>payload: {books, candidate_ids, query}
    end
    
    RP-->>RC: preference_vector + sentiment
    BC-->>RC: content_vectors + book_tags
    
    RC->>RC: 构建 ranking 候选集<br/>合并向量 + 标签 + KG 信号
    
    RC->>RR: RPC /rec-ranking/rpc<br/>payload: {profile_vector, candidates, weights}
    
    RR->>RR: 多因子评分<br/>协同过滤 + 语义 + 知识 + 多样性
    
    RR-->>RC: ranking + explanations + metrics
    
    RC->>RC: 评估指标计算
    RC-->>User: 推荐结果 + 解释 + 评估
```

---

## 数据流转

```mermaid
flowchart LR
    subgraph 输入层
        U[用户 query]
        P[user_profile]
        H[阅读历史 history]
        R[书评 reviews]
        B[书籍候选 books]
    end
    
    subgraph ReaderProfile
        P1[偏好向量 genres/themes/tones]
        P2[情感分析 sentiment]
        P3[意图关键词 intent_keywords]
    end
    
    subgraph BookContent
        C1[内容向量 content_vectors]
        C2[书籍标签 book_tags]
        C3[KG 引用 kg_refs]
    end
    
    subgraph RecRanking
        R1[协同过滤分数]
        R2[语义相似度]
        R3[KG 信号]
        R4[多样性/新颖性]
        R5[综合排序 ranking]
    end
    
    U --> BC
    P --> RP
    H --> RP
    R --> RP
    B --> BC
    
    RP --> P1
    RP --> P2
    BC --> C1
    BC --> C2
    BC --> C3
    
    P1 --> RR
    C1 --> RR
    C2 --> RR
    C3 --> RR
    
    RR --> R1 & R2 & R3 & R4
    R1 & R2 & R3 & R4 --> R5
```

---

## 关键发现

1. **三层架构**: ReadingConcierge 作为 Leader 编排，3 个 Agent 作为 Partner 并行/串行执行

2. **并行优化**: ReaderProfile 和 BookContent 可并行调用，RecRanking 需等待两者结果

3. **RPC 通信**: 所有 Agent 通过 AIP RPC 协议通信，支持本地调用和远程发现

4. **场景感知**: 系统识别 cold/warm/explore 三种场景，动态调整排序权重

5. **多因子评分**: RecRanking 使用 4 个信号源 (协同 25% + 语义 35% + 知识 20% + 多样性 20%)

6. **KG 集成**: BookContent 从知识图谱提取作者/流派节点，增强内容理解

7. **降级策略**: 支持远程/本地双模式，远程失败时自动降级到本地 Agent

8. **端点配置**:
   - ReaderProfile: `:8211` / `/reader-profile/rpc`
   - BookContent: `:8212` / `/book-content/rpc`
   - RecRanking: `:8213` / `/rec-ranking/rpc`
   - ReadingConcierge: `:8100` / `/user_api`

---

## 请求处理链路总结

```
用户请求 → ReadingConcierge(场景识别) 
         → [ReaderProfile + BookContent] 并行 
         → RecRanking(多因子排序) 
         → 返回推荐结果
```
