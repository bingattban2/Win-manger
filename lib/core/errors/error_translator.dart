import 'package:adwas_personnel/core/errors/operation_failures.dart';

abstract final class ErrorTranslator {
  static String operation(OperationFailure failure) => switch (failure.code) {
    OperationFailureCode.invalidInput => 'البيانات المدخلة غير صحيحة.',
    OperationFailureCode.unauthenticated => 'يرجى تسجيل الدخول مجددًا.',
    OperationFailureCode.permissionDenied => 'ليس لديك صلاحية لتنفيذ العملية.',
    OperationFailureCode.notFound => 'تعذر العثور على السجل المطلوب.',
    OperationFailureCode.businessRule => 'تعذر تنفيذ العملية بسبب قواعد النظام.',
    OperationFailureCode.stalePreview =>
      'تغيرت البيانات بعد المعاينة. يرجى مراجعتها من جديد.',
    OperationFailureCode.confirmationRequired =>
      'يجب تأكيد العملية قبل تنفيذها.',
    OperationFailureCode.alreadySubmitted =>
      'تم استخدام طلب العملية أو انتهت صلاحيته.',
    OperationFailureCode.persistenceUnavailable =>
      'حفظ البيانات غير متاح قبل تفعيل قاعدة البيانات المشفرة.',
  };
}
