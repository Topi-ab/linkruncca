# Optimizing critical path for Feature Accumulator.

## Original design

In the original design, the longest asynchronous datapath is from memory to DFF inside Feature Accumulator.

This datapath consists of:
- Data selection (Data selection)
- Merging feature from memory to current feature in Feature Accumulator register (Merge Memory to Current).
- Merging feature from current pixel to current feature in Feature Accumulator register (Merge Pixel to Current).
- Clearing the feature to a empty collection (Clear Current).

```mermaid
flowchart LR
    mux([Data MUX])
    mem[RAM]
    async_1([Data selection])
    async_2([Merge Memory to Current])
    async_3([Merge Pixel to Current])
    async_4([Clear Current])
    dff1[DFF 1]

    mux --> mem
    mem --> async_1
    async_1 --> mux
    async_1 --> async_2
    async_2 -->|dp| async_3
    async_3 --> async_4
    async_4 --> dff1
    dff1 --> async_2
    dff1 -->|d| mux
```

## Optimized design.

Here the idea is that the order of feature merging does not matter, and the loop from `DFF 1` to `Merge Memory to Current` can be made shorter.

Now the longest asynchronous datapath is either `Data selection`-`Merge Pixel to Current`
or `Merge Memory to Current`-`Clear Current`-`Data Mux`.

```mermaid
flowchart LR
    mux([Data MUX])
    mem[RAM]
    async_1([Data Path])
    async_2([Merge Memory to Current])
    async_3([Merge Pixel to Current])
    async_4([Clear Current])
    dff1[DFF 1]
    dff2[DFF 2]

    mux --> mem
    mem --> async_1
    async_1 --> mux
    async_1 -->|dp| async_3
    async_3 -->|d_pix| dff1
    dff1 -->|d_pix_d1| async_2
    async_2 -->|d_current| dff2
    dff2 -->|d_acc| async_2
    async_2 -->|d_current| async_4
    async_4 -->|d| mux
```
