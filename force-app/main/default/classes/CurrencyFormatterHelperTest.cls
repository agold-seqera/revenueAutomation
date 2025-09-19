@isTest
public class CurrencyFormatterHelperTest {
    
    @isTest
    static void testBasicFormatting() {
        List<CurrencyFormatterHelper.FormatInput> inputs = new List<CurrencyFormatterHelper.FormatInput>();
        
        CurrencyFormatterHelper.FormatInput input1 = new CurrencyFormatterHelper.FormatInput();
        input1.amount = 1234567.89;
        inputs.add(input1);
        
        CurrencyFormatterHelper.FormatInput input2 = new CurrencyFormatterHelper.FormatInput();
        input2.amount = null;
        inputs.add(input2);
        
        Test.startTest();
        List<CurrencyFormatterHelper.FormatOutput> results = CurrencyFormatterHelper.formatCurrency(inputs);
        Test.stopTest();
        
        System.assertEquals(2, results.size());
        System.assertNotEquals(null, results[0].formattedAmount);
        System.assertEquals('$0.00', results[1].formattedAmount);
    }
}