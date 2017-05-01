;;; mastodon-render.el --- Rendering toots form mastodon.el

;; Copyright (C) 2017 Johnson Denen
;; Author: Johnson Denen <johnson.denen@gmail.com>
;; Version: 0.6.1
;; Homepage: https://github.com/jdenen/mastodon.el

;; This file is not part of GNU Emacs.

;; This file is part of mastodon.el.

;; mastodon.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; mastodon.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with mastodon.el.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; mastodon-render.el provides an alternate rendering for mastodon.el
;; need to document

;;; Code:

(require 'time-date)

(defcustom mastodon-render-waring-string " ----cw---- \n"
  "The warning string for a toot.")

(defcustom mastodon-render-boosted-string "(B) "
  "Appears before toot when a user has boosted it.")

(defcustom mastodon-render-favourited-string "(F) "
  "Appears before toot when a user has favourited it.")

(defcustom mastodon-render-reblog-string "BOOSTED"
  "The string that appears between two users after boosting.")

(defun mastodon-render--get-field (event field)
  (cdr (assoc field event)))

(defun mastodon-render--get-field-2 (event field-1 field-2)
  (mastodon-render--get-field (mastodon-render--get-field event field-1) field-2))

(defun mastodon-render--get-field-3 (event field-1 field-2 field-3)
  (mastodon-render--get-field (mastodon-render--get-field-2 event field-1 field-2) field-3))


(defun mastodon-render--html (string)
  (with-temp-buffer
    (insert (decode-coding-string string 'utf-8))
    (shr-render-region (point-min) (point-max))
    (goto-char (point-max))
    (delete-region (point) (progn (skip-chars-backward "\n") (point)))
    (insert "\n")
    (buffer-string)))

(defun mastodon-render--get-spoiler-text (event)
  (let* ((spoiler-value (mastodon-render--get-field event 'spoiler_text))
         (spoiler (if (equal spoiler-value "")
                      ""
                    (mastodon-render--process-spoiler))))
    (list spoiler (list 'type :spoiler-text 'face 'default))))

(defun mastodon-render--get-cw (event)
 (let ((cw(if (equal "" (mastodon-render--get-field event 'spoiler_text))
              ""
            mastodon-render-waring-string)))
 (list cw
       (list 'type :cw
             'hidden :false
             'face 'success))))

(defun mastodon-render--get-content (event)
  (let ((content (mastodon-render--process-content
                  (mastodon-render--get-field event 'content))))
    (list content
          (list 'type :content
                'face 'default))))

(defun mastodon-render--get-images (event)
  (let*((media-list (append
                     (mastodon-render--get-field
                      event
                      'media_attachments)
                     nil))
        (media-string (if (> (length media-list) 0) 
                          (concat (mapconcat
                           (lambda(media)
                             (concat "Media_Link:: "
                                     (cdr(assoc 'preview_url media))))
                           media-list "\n") "\n")
                        "" ;;else
                        )))
    (list  media-string
           (list
                'type :media
                'number (length media-list)
                'attachments media-list
                'face 'default))))

(defun mastodon-render--get-boosted (event)
  (let((boost (if (equal (mastodon-render--get-field event 'reblogged)
                         :json-true)
                  mastodon-render-boosted-string
                "")))
        (list boost
              (list 'type :boosted
                    'face 'success))))

(defun mastodon-render--get-favourited (event)
  (let((fave (if (equal (mastodon-render--get-field event 'favourited)
                        :json-true)
                mastodon-render-favourited-string
                "")))
        (list fave
              (list 'type :favourited
                    'face 'success))))


(defun mastodon-render--get-display-name (event)
  (let ((user
         (mastodon-render--process-display-name
         (mastodon-render--get-field-2 event 'account 'display_name))))
    (list user
          (list
           'type :display-name
           'face 'warning))))

(defun mastodon-render--get-acct (event)
  (let ((acct (concat "(@"
                      (mastodon-render--get-field-2 event 'account 'acct)
                      ")")))
    (list  acct
           (list 'type :acct
                 'face 'default))))

(defun mastodon-render--get-reblog (event)
  (let((rebloger(if (mastodon-render--get-field event 'reblog)
                    mastodon-render-reblog-string
                  "")))
    (list rebloger
          (list 'type :reblog
                'face 'success))))

(defun mastodon-render--get-reblog-display-name (event)
  (let((rebloger(if (mastodon-render--get-field event 'reblog)
                    (mastodon-render--process-display-name
                     (mastodon-render--get-field-3 event
                                 'reblog
                                 'account
                                 'display_name))
                  "")))
    (list rebloger
          (list 'type :reblog-diplay-name
                'face 'warning))))

(defun mastodon-render--get-reblog-acct (event) 
  (let (( re-acct(if (mastodon-render--get-field event 'reblog)
                     (concat "(@"(mastodon-render--get-field-3 event 'reblog 'account 'acct)
                             ")")
                   "")))
    (list re-acct
          (list 'type :reblog-acct                
                'face 'default))))

(defun mastodon-render--get-time (event)
  (let((time
        (mastodon-render--process-time
          (mastodon-render--get-field event 'created_at))))
    (list time
          (list 'type :time                
                'face 'default))))

(defun mastodon-render--process-spoiler (string)
  (mastodon-render--html string))
 
(defun mastodon-render--process-content (string)
  (mastodon-render--html string))

(defun mastodon-render--process-time (string)
  (format-time-string
   mastodon-toot-timestamp-format (date-to-time string)))

(defun mastodon-render--process-display-name (string)
  (decode-coding-string string 'utf-8))

(defun mastodon-render--toot-string-layout (event)
  (let ((spoiler-text (mastodon-render--get-spoiler-text event))
        (cw (mastodon-render--get-cw event))
        (content (mastodon-render--get-content event))
        (images (mastodon-render--get-images event))
        (boosted (mastodon-render--get-boosted event))
        (favourited (mastodon-render--get-favourited event))
        (display-name (mastodon-render--get-display-name event))
        (acct (mastodon-render--get-acct event))
        (reblog (mastodon-render--get-reblog event))
        (reblog-display-name (mastodon-render--get-reblog-display-name event))
        (reblog-acct (mastodon-render--get-reblog-acct event))
        (time (mastodon-render--get-time event)))
    (mastodon-render--toot-add-default
     `(,spoiler-text
      ,cw 
      ,content 
      ,images 
      " | " ,boosted "" ,favourited ""
      ,display-name  ,acct 
      ,reblog " " ,reblog-display-name
      ,reblog-acct " " ,time "\n"
      " ----------\n"))))


(defun mastodon-render--toot-add-default (alist)
    (mapcar
      (lambda(x)
       (if (stringp x)
           (list x '(type :visual face default))
         x))
      alist))

(defun mastodon-render--toot-string-compose (alist)
  (let ((prev 0)
        (range-list '())
        (out-string "")
        (list alist))
    (message "in")
    (while (cadr list)
      (let* ((string (pop list))
             (start prev)
             (end (+ prev (length (car string))))             
             (range (list  (or (plist-get (second string) 'type)
                               :visual)
                           start end)))
        (push range range-list)
        (message (car string))
        (setq prev (+ prev (- end start)))
        (setq out-string (concat out-string (car string)))))
    (print out-string)
    (list out-string  (reverse range-list))))

(defun mastodon-render--propertized-toot (event compile-toot-layout)
  (let* ((toot-layout (mastodon-render--toot-string-compose
                       (funcall compile-toot-layout event)))
         (toot-string (car toot-layout))
         (ranges (cdr toot-layout)) 
        (boosted (< (length(mastodon-render--get-boosted event) )0))
        (favourited (< (length(mastodon-render--get-favourited event) )0))
        (cw (< (length(mastodon-render--get-cw event ) )0))
        (toot-id (mastodon-render--get-field event 'id)))
    (propertize toot-string                
                'toot-id toot-id                
                'boosted boosted
                'favourited favourited
                'cw cw
                'ranges ranges)))

(defun mastodon-render--toot (event)
  (insert (mastodon-render--propertized-toot
           event
           'mastodon-render--toot-string-layout)))

(defun mastodon-render--check-proporties ()
  (interactive )
  (let* ((props  (text-properties-at (point) ))
         (buffer (get-buffer-create "proporties")))
    (with-current-buffer buffer (insert(pp props))) (display-buffer buffer)))

(defun mastodon-render--goto-part (part fun)
  (let ((range (assoc
                part
                (car(plist-get
                     (text-properties-at (point))
                     'ranges)) )))
    (goto-char (funcall fun range ))))

;; example mastodon-render--toggle-value(:boosted )
(defun mastodon-render--toggle-value (part)
  ;; there will be a true and false rendering for each part
  ;; the state will be known, by toggling this you switch
  ;; the state
  ;; In addition for all regions that start after this point
  ;; their start and end values area djusted by the difference
  ;; in the toggle widths (eg "" "(B) " -> 0,4)
  ;; for now false is "" for all parts
  )

;; (insert(default-toot *boost-buffer* 'default-compile-toot-string))
;;(setq debug-on-error 't)
(defun mastodon-tl--toot (event)
  (insert (mastodon-render--propertized-toot
           event
           'mastodon-render--toot-string-layout)))

(provide 'mastodon-render)
;;; mastodon-render.el ends here
