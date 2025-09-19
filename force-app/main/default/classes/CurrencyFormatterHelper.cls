public with sharing class CurrencyFormatterHelper {
    
    public class FormatInput {
        @InvocableVariable(required=true)
        public Decimal amount;
    }
    
    public class FormatOutput {
        @InvocableVariable
        public String formattedAmount;
        @InvocableVariable
        public String errorMessage;
    }
    
    @InvocableMethod(label='Format Currency')
    public static List<FormatOutput> formatCurrency(List<FormatInput> inputs) {
        List<FormatOutput> outputs = new List<FormatOutput>();
        
        for (FormatInput input : inputs) {
            FormatOutput output = new FormatOutput();
            
            try {
                if (input.amount == null) {
                    output.formattedAmount = '$0.00';
                } else {
                    // Try Apex's built-in format method with proper decimal formatting
                    String formattedNumber = input.amount.setScale(2).format();
                    // Ensure it ends with .XX format
                    if (!formattedNumber.contains('.')) {
                        formattedNumber += '.00';
                    } else if (formattedNumber.split('\\.')[1].length() == 1) {
                        formattedNumber += '0';
                    }
                    output.formattedAmount = '$' + formattedNumber;
                }
            } catch (Exception e) {
                output.formattedAmount = null;
                output.errorMessage = 'Formatting failed: ' + e.getMessage();
            }
            
            outputs.add(output);
        }
        
        return outputs;
    }
}