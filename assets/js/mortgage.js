function getAnnuitetePayment(sum, lengthInMonths, yearlyInterest) {
  if (sum <= 0) throw "Sum should be zero or more";
  if (lengthInMonths <= 0) throw "lengthInMonths should be zero or more";
  if (yearlyInterest <= 0) throw "yearlyInterest should be zero or more";

  var monthlyInterest = yearlyInterest / 12;
  var x = Math.pow(1 + monthlyInterest, lengthInMonths);
  var coeff = monthlyInterest * x / (x - 1);
  return sum * coeff;
}

function calculateLength(sum, lengthInMonths, yearlyInterest, pay) {
  var minimumPayment = getAnnuitetePayment(sum, lengthInMonths, yearlyInterest);
  if (minimumPayment > pay) {
    throw "Minimum payment is lower than your pay";
  }

  var length = 0;
  while (sum > 0) {
    var interestPay = sum * yearlyInterest / 12;
    var sumReduce = pay - interestPay;
    sum -= sumReduce;
    length++;
  }

  return length;
}
