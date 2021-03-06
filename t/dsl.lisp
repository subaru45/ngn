#|
  This file is a part of ngn project.
  Copyright (c) 2013 subaru45
|#

(in-package :cl-user)
(defpackage ngn.dsl-test
  (:use :cl
        :ngn.error
        :ngn.parser
        :prove))
(in-package :ngn.dsl-test)


(plan 8)

(defmacro tests-with-syntax-error (linum tagname msg &body body)
  `(handler-case
       (progn
         (init-linum)
         (init-tag-name)
         ,@body)
     (dsl-syntax-error (c)
       (let ((linum-got (ngn.error::syntax-error-linum c))
             (tagname-got (ngn.error::syntax-error-tagname c))
             (msg-got (ngn.error::syntax-error-message c)))
         (is linum-got ,linum)
         (is tagname-got ,tagname)
         (is msg-got ,msg)))))


(subtest "Testing read-before-newline"
  (flet ((call-it (str)
           (with-input-from-string (in str)
             (ngn.dsl::read-before-newline in))))
    (is (call-it "0123") "0123")
    (is (call-it "012345
6789#") "012345")))


(subtest "Testing get-level"
  (flet ((call-it (ch str)
           (with-input-from-string (in str)
             (ngn.dsl::get-level ch in))))
    (multiple-value-bind (lev str)
        (call-it #\# "#### ")
      (is lev 4)
      (is str "####"))
    (multiple-value-bind (lev str)
        (call-it #\# "####")
      (is lev 4)
      (is str "####"))
    (multiple-value-bind (lev str)
        (call-it #\# "####a")
      (is lev 4)
      (is str "####"))))


(subtest "Testing bracket-reader"
  (flet ((call-it (str)
           (with-input-from-string (in str)
             (ngn.dsl::bracket-reader in))))
    (is (call-it "[]") "")
    (is (call-it "[string]") "string")
    (is (call-it "[string]s") "string")

    (subtest "error case"
      (tests-with-syntax-error
       1 nil "Unexpected NEWLINE while looking for ']'"
       (call-it "[abc
abc]"))
      (tests-with-syntax-error
       1 nil "Unexpected EOF while looking for ']'"
       (call-it "[")))))


(subtest "Testing element-reader"
  (flet ((call-it (str)
           (with-input-from-string (in str)
             (ngn.dsl::element-reader in))))
    (let ((*package* (find-package :ngn.dsl)))
      (load "t/test-renderer.lisp"))

    (is (call-it "rb[str1][str2]") "rb-str1str2")
    (is (call-it "em[str]") "em-str")
    (is (call-it "bd[str]") "bd-str")
    (is (call-it "it[str]") "it-str")
    (is (call-it "bi[str]") "bi-str")
    (is (call-it "ul[str]") "ul-str")
 
    (subtest "error case"
      (tests-with-syntax-error
        1 nil "'aa' is not ngn-element"
        (call-it "aa")))))


(subtest "Testing sharp-reader"
  (flet ((call-it (str lhp)
           (with-input-from-string (in str)
             (ngn.dsl::sharp-reader in lhp))))
    (let ((*package* (find-package :ngn.dsl)))
      (load "t/test-renderer.lisp"))

    (subtest "non line-head"
      (is (call-it "#rb[s1][s2]" nil) "rb-s1s2")
      (is (call-it "# header" nil) "#"))

    (subtest "line-head"
      (is (call-it "#rb[s1][s2]" t) "rb-s1s2")
      (is (call-it "# header" t) "hd1-header"))

    (subtest "boundary about header syntax"
      (is (call-it "#+++" nil) "#")
      (is (call-it "#+++" t) "#+"))

    (subtest "boundary about header level"
      (is (call-it "### header" t) "hd3-header")
      (is (call-it "#### header" t) "hd4-header")
      (is (call-it "##### header" t) "#####"))))


(subtest "Testing greater-reader"
  (flet ((call-it (str lhp)
           (with-input-from-string (in str)
             (ngn.dsl::greater-reader in lhp))))
    (let ((*package* (find-package :ngn.dsl)))
      (load "t/test-renderer.lisp"))

    (is (call-it "> str" nil) ">")
    (is (call-it "> str" t) "qt1-str")
    (is (call-it "> line1
> line2" t)
        "qt1-line1
line2")
    (is (call-it ">>test" t) ">>")
    (is (call-it ">> test
>str" t)
        "qt2-test
>")

    (subtest "boundary"
      (is (call-it ">> str" t)
          "qt2-str")
      (is (call-it ">>> str" t)
          "qt3-str")
      (is (call-it ">>>> str" t)
          "qt4-str")
      (is (call-it ">>>>> str" t)
          ">>>>>"))

    (subtest "sharp-reader in quotation"
      (is (call-it "> #rb[text][ruby]" t)
          "qt1-rb-textruby")
      (is (call-it "> The #em[quick] brown fox ..." t)
          "qt1-The em-quick brown fox ...")
      ; In quotation, header is ignored
      (is (call-it "> # header" t)
          "qt1-# header"))

    (subtest "multiline"
      (is (call-it "> line-qt1
>>> line-qt3" t)
          "qt1-line-qt1
qt3-line-qt3")
      (is (call-it "> line-qt1
normal-line" t)
          "qt1-line-qt1")
      (is (call-it ">> line-qt2
>> line-qt2
>>>> line-qt4
>>>> line-qt4
> line-qt1" t)
          "qt2-line-qt2
line-qt2
qt4-line-qt4
line-qt4
qt1-line-qt1"))))


(subtest "Testing dsl-reader"
  (flet ((call-it (str)
           (with-input-from-string (in str)
             (ngn.dsl::dsl-reader in))))
    (let ((*package* (find-package :ngn.dsl)))
      (load "t/test-renderer.lisp"))

    (subtest "boundary about header"
      (is (call-it "#+++") "#+++"))

    (subtest "non line-head"
      (is (call-it " #rb[s1][s2]") " rb-s1s2")
      (is (call-it " > str") " > str"))

    (subtest "line-head"
      (is (call-it "#rb[s1][s2]") "rb-s1s2")
      (is (call-it "> str") "qt1-str"))

    (subtest "quotation"
      (is (call-it ">str") ">str")
      (is (call-it "> str1
>>str2")
          "qt1-str1
>>str2")

      (is (call-it ">> str1
> str2")
          "qt2-str1
qt1-str2")
      (is (call-it ">> str1
>str2")
          "qt2-str1
>str2"))

    (subtest "multiline"
      (is (call-it "# header1
## header2")
          "hd1-header1
hd2-header2")
      (is (call-it " # header
>> quote")
          " # header
qt2-quote"))))


(subtest "Testing render-tag"
  (flet ((call-it (str)
           (ngn.dsl::render-tag str)))
    (let ((*package* (find-package :ngn.dsl)))
      (load "t/test-renderer.lisp"))

    (subtest "non line-head"
      (is (call-it " #rb[s1][s2]") " rb-s1s2")
      (is (call-it " # rb[s1][s2]") " # rb[s1][s2]"))

    (subtest "line-head"
      (is (call-it "#rb[s1][s2]") "rb-s1s2")
      (is (call-it "# rb[s1][s2]") "hd1-rb[s1][s2]"))

    (subtest "multi-line"
      (is (call-it "#em[str1]
#bd[str2]")
          "em-str1$
bd-str2$
")
      (is (call-it "# header1
# header2")
          "hd1-header1
hd1-header2
"))))


(finalize)
