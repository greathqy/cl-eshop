(in-package #:eshop)


(defun write-products-report (stream)
  (format stream "~a;~a;~a;~a;~a;~a;~a;~a;~a;~a;~a;~%"
          "артикул"
          "имя"
          "имя real"
          "имя yml"
          "seo текст"
          "фотографии"
          "характеристики"
          "активный"
          "группа"
          "родительская группа"
          "secret")
  (maphash #'(lambda (k v)
               (let ((id "нет")
                     (name "нет")
                     (name-real "нет")
                     (name-yml "нет")
                     (desc "нет")
                     (img "нет")
                     (option "нет")
                     (active "нет")
                     (group-name "нет")
                     (parent-group-name "нет")
                     (secret "нет"))
                 (when (equal (type-of v)
                              'product)
                   (setf id (articul v))
                   (setf name (stripper (name v)))
                   (setf name-real (stripper (realname v)))
                   (with-option v "Secret" "Yandex"
                                (setf name-yml (stripper (value option))))
                   (setf desc (if (and (not (null (descr v)))
                                       (not (string= "" (stripper (descr v)))))
                                  "есть"
                                  "нет"))
                   (setf img (length (get-pics (articul v))))
                   (setf options (if (not (null (optgroups v)))
                                     "есть"
                                     "нет"))
                   (setf active (if (active v)
                                    "да"
                                    "нет"))
                   (setf group-name (if (not (null (parent v)))
                                        (stripper (name (parent v)))))
                   (setf parent-group-name (if (and (not (null (parent v)))
                                                    (not (null (parent (parent v)))))
                                               (stripper (name (parent (parent v))))))
                   (setf secret "Нет")
                   (with-option v "Secret" "Checked"
                                (setf secret (value option)))
                   (format stream "~a;\"~a\";\"~a\";\"~a\";~a;~a;~a;~a;\"~a\";\"~a\";~a;~%"
                           id
                           name
                           name-real
                           name-yml
                           desc
                           img
                           options
                           active
                           group-name
                           parent-group-name
                           secret)
                   )))
           *storage*))


(defun write-groups (stream)
  (format stream "~a;~a;~a;~a;~%"
          "Название категории"
          "url страницы"
          "Active"
          "seo-text")
  (maphash #'(lambda (k v)
               (declare (ignore k))
               (when (equal (type-of v)
                              'group)
                 (format stream "\"~a\";http://www.320-8080.ru/~a;~a;~a;~%"
                           (stripper (name v))
                           (key v)
                           (if (active v)
                               "yes"
                               "no")
                           (if (and (not (null (descr v)))
                                       (not (string= "" (stripper (descr v)))))
                                  "yes"
                                  "no"))
                   ))
           *storage*))



(defun write-products (stream)
  (let ((vendor-name)
        (desc))
    (format stream "~a;~a;~a;~a;~a;~a;~%"
            "Название категории"
            "Брэнд"
            "Название товара"
            "url страницы"
            "Active"
            "seo-text")
    (maphash #'(lambda (k v)
                 (declare (ignore k))
                 (when (equal (type-of v)
                              'product)
                   (setf vendor-name "Нет")
                   (with-option v "Общие характеристики" "Производитель"
                                (setf vendor-name (value option)))
                   (setf desc (if (and (not (null (shortdescr v)))
                                       (not (string= "" (stripper (shortdescr v)))))
                                  "yes"
                                  "no"))
                   (format stream "\"~a\";\"~a\";\"~a\";http://www.320-8080.ru/~a;~a;~a;~%"
                           (if (not (null (parent v)))
                               (stripper (name (parent v)))
                               "Нет категории")
                           (stripper vendor-name)
                           (stripper (realname v))
                           (articul v)
                           (if (active v)
                               "yes"
                               "no")
                           desc)))
             *storage*)))


(defun write-vendors (stream)
  (format stream "~a;~a;~a;~a;~a;~%"
          "Название категории"
          "Брэнд"
          "url страницы"
          "Active"
          "seo-text")
  (maphash #'(lambda (k v)
               (declare (ignore k))
               (when (and (equal (type-of v)
                            'group)
                          (null (childs v)))
                 (mapcar #'(lambda (vendor)
                             (format stream "\"~a\";\"~a\";http://www.320-8080.ru/~a?vendor=~a;~a;~a;~%"
                                     (stripper (name v))
                                     (stripper (car vendor))
                                     (key v)
                                     (stripper (car vendor))
                                     "yes"
                                     (let ((desc (gethash (car vendor) (vendors v))))
                                       (if (and (not (null desc))
                                                (not (string= "" desc)))
                                           "yes"
                                           "no"))))
                         (producersall (make-producers v)))))
           *storage*))

(defun create-report (file-name report-func)
  (let ((filename (format nil "~a/~a" *path-to-dropbox* file-name)))
    (with-open-file
        (stream filename :direction :output :if-exists :supersede)
      (funcall report-func stream))))


(defun check-valid-siteprice ()
  (format t "~&~a;\"~a\";~a;~a;~a;"
          "Артикул"
          "Имя"
          "Активный"
          "Цена магазина"
          "Цена 3208080")
  (maphash #'(lambda(k v)
               (declare (ignore k))
               (when (equal (type-of v)
                            'product)
                 (if (< (price v)
                        (siteprice v))
                     (format t "~&~a;\"~a\";~a;~a;~a;"
                             (articul v)
                             (stripper (name v))
                             (if (active v)
                                 "yes"
                                 "no")
                             (price v)
                             (siteprice v)))))
           *storage*))

(defun show-last-history (stream)
  (when (not (null *history*))
    ;; Делаем все продукты неактивными
    (maphash #'(lambda (k v)
                 (declare (ignore k))
                 (when (equal (type-of v) 'product)
                   (setf (active v) nil)))
             *storage*)
    (loop :for packet :in (reverse (caddr (car *history*))) :do
       (format stream "~a" (sb-ext:octets-to-string packet :external-format :cp1251)))))

;; (create-report "seo/last-gateway-string.txt" #'show-last-history)
;; (create-report "xls/products.csv" #'write-products-report)
;; (create-report "seo/report-groups.csv" #'write-groups)
;; (create-report "seo/report-products.csv" #'write-products)
;; (create-report "seo/report-vendors.csv" #'write-vendors)


(mapcar #'(lambda (v)
            (let ((p (gethash v *storage*)))
              (when (not (null p))
                  (setf (predzakaz p) t)
                  (serialize p))))
        (list "166545"
              "166578"
              "166579"
              "166580"
              "166581"
              "167310"
              "167475"
              "167530"
              "167531"
              "167532"
              "167533"
              "167534"
              "167535"))


(mapcar #'(lambda (v)
            (let ((p (gethash v *storage*)))
              (when (not (null p))
                (serialize p))))
        (list
         "150096"
         "162029"
         "144952"
         "148956"
         "163737"
         "161139"
         "162907"
         "160141"
         "150061"
         "165392"
         "160411"
         "161133"
         "163736"
         "150523"
         "163524"
         "158276"
         "150525"
         "162032"
         "150060"
         "163835"
         "159535"
         "158278"
         "162031"
         "149482"
         "148494"
         "149531"))


(setf (active (gethash "160420" *storage*)) nil)
(setf (active (gethash "165359" *storage*)) nil)
(setf (active (gethash "165360" *storage*)) nil)




(defun test-view-g (g)
  (let ((ch (childs g))
        (rs))
    (if (null ch)
        (list g)
        (progn
          (mapcar #'(lambda (g)
                      (setf rs (append rs (test-view-g g))))
                  ch)
          rs))))
