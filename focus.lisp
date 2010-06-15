;; -*- mode: Lisp; Syntax: Common-Lisp; Package: qooxlisp; -*-
#|

    focus -- abstract focus handling

(See package.lisp for license and copyright notigification)

|#


(in-package :qxl)

#| To do

- IXEditSelection needs a home

;;; also got FFComposite rule deciding it was active if any kid was

arrange for Focuser to process clicks and keys first, then mebbe dump into dvk,
bottom up from focus/imageunder

arrange for Controller to process clicks first, then mebbe dump into 
bottom up from focus/imageunder

add finalization for radio button (look at others, see if ICR can ne de-celled

|#


(defmd focuser ()
  (focus (c-in nil))
  
  (edit-active (c-in nil))
  (insertion-pt (c-in 0))
  (sel-end (c-in nil))
  (sel-range nil :documentation "selEnd identified during drag operation")
  (undo-data nil :cell nil
    :documentation "Data structure holding undo information"))


(export! ^focus focus .focus focus-find-first .focuser)

;;;(defobserver focus ((self focuser))
;;;  (when (and (null new-value) old-value)
;;;            (break "focus nilling"))
;;;  (TRC "focus-observe" self new-value old-value))

(defun focuser (self)
  (u^ qxl-session))

(define-symbol-macro .focuser (focuser self))
  
(defmethod (setf focus) :around (new-focus self) ;; better be Focuser
  (let ((curr-focus (slot-value self 'focus)))
    (trc nil "setf focus sees new" new-focus :old curr-focus :focuser self)
    (unless (eql new-focus curr-focus)
      (focus-lose curr-focus new-focus)
      (focus-gain new-focus))
    (call-next-method)))

(defun focus-on-dbg (self new-focus dbg)
  (declare (ignorable dbg))
  (trc nil "dbg focus by" dbg :on new-focus :self self)
  (setf .focus new-focus))

(export! focused-on ^focused-on focus-on-dbg)

(defmodel focus ()
  ((focus-thickness :cell nil :initarg :focus-thickness
                   :initform 3
                   :accessor focus-thickness)

   (tab-mode :documentation ":ceiling :stop or nil"
            :cell nil :initarg :tab-mode
            :initform :stop
            :accessor tab-mode)

   (focused-on :initarg :focused-on
               :initform (c-in nil)
               :accessor focused-on)))

(defun tabstopp (self)
  (eql :stop (tab-mode self)))

(defmethod tab-mode (other)
   (declare (ignore other))
   nil)

(defmethod edit-requires-activation (self)
  (declare (ignore self)))

(defmodel focus-minder ()
  ;
  ; an entity which remembers which descendant was focused when the
  ; window focus moves outside the FocusMinder. This 'minded' focus
  ; is restored as the window's focus if the FocusMinder itself
  ; becomes the window's focus (if no minded focus, we focus-first)
  ;
  ((focus-minded :accessor focus-minded :initarg :focus-minded
                :initform (c? (let ((focus .focus))
                                 (if (fm-includes self focus)
                                     (if (eql self focus)
                                         .cache
                                       focus)
                                   .cache))))))

(export! focus-handle-keysym)

(defgeneric focus-handle-keysym (self keysym)
  (:method :around (self keysym)
    (let ((r (call-next-method)))
      (when (and (not (eq r :focus-handle-keysym-break))
              .parent)
        (focus-handle-keysym .parent keysym))))
  (:method (self keysym)
    (declare (ignore self keysym))
    nil))

;------------------------------

(defmethod turn-edit-active (self new-value)
  (declare (ignorable self new-value)))

(defmethod focus-shared-by (f1 f2)
  (declare (ignore f1 f2))
  nil)


(defmethod focus-starting ((self focus-minder))
  (or (focus-minded self)
      (focus-find-first self)
      (focus-find-first self :tab-stop-only nil)))

(export! focus-on)

(defmethod focus-on (self &optional focuser)
  (c-assert (or self focuser))
  #+xxx (trc "focus.on self, focuser" self focuser .focuser (focus-state .focuser))
  ;; (break "focus.on self, focuser")
  (setf (focus (or focuser .focuser)) self))

(defgeneric focus-gain (self)
  (:method (self) (declare (ignore self)))
  (:method ((self focus))
    (trc nil "setting focused-on true" self)
    (setf (^focused-on) t)))

(defgeneric focus-lose (self new-focus)
  (:method (self new-focus) (if self
                      (focus-lose (fm-parent self) new-focus)
                    t))
  (:method :around ((self focus) new-focus)
    (declare (ignore new-focus))
    (when (call-next-method)
      (setf (^focused-on) nil))))

;________________________________ I d l i n g _______________________
;
(defmethod focus-idle (other) (declare (ignorable other)))

(defmethod focus-idle ((list list))
  (dolist (f list)
    (focus-idle f)))

;_____________________ I n t o - V i e w _____________________
; 
; 990329 /// kt Resurrect eventually
;
(defmethod focus-scroll-into-view ((focus focus))
  ;;  temp to get going (view-scroll-into-view focus)
  )

(defmethod focus-scroll-into-view (other)
  (declare (ignore other)))

(defmethod focus-scroll-into-view ((focii list))
  (dolist (focus focii)
    (focus-scroll-into-view focus)))

(defun focusable? (focus &optional (test #'true) (tab-stop-only t))
  (and (typep focus 'focus)
    (fully-enabled focus)
    (or (not tab-stop-only)
      (tabstopp focus))
    (funcall test focus)))

(export! focus-find-first focus-find-next focus-find-prior)

(defun focus-find-first (self &key (test #'true) (tab-stop-only t))
  (fm-find-if self (lambda (x)
                      (focusable? x test tab-stop-only))))

(defun focus-find-next (self &key (test #'true) (tab-stop-only t))
  (fm-find-next self (lambda (x)
                      (focusable? x test tab-stop-only))))

(defun focus-find-prior (self &key (test #'true) (tab-stop-only t))
  (fm-find-prior self (lambda (x)
                        (focusable? x test tab-stop-only))))


