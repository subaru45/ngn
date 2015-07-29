;;;;
;;;; ngn の構文早見表
;;;;


;; ルビ
#rb[文字列][ルビ文字列]

;; 強調(傍点)
#em[文字列]

;; 太字
#bd[txt]

;; イタリック体
#it[txt]

;; 太字でイタリック体
#bi[txt]

;; 下線
#ul[txt]


;; 見出し
;; '#'の数が見出しのレベルに対応する
# 見出しレベル1
## 見出しレベル2
### 見出しレベル3
#### 見出しレベル4


;; 引用
;; '>'の数が引用のレベルに対応する
> 引用レベル1
> 二行目
> #rb[漢字][よみがな]のようにルビも使える。

>> 引用レベル2
>> 二行目

>>> 引用レベル3
>>> 二行目

>>>> 引用レベル4
>>>> 二行目