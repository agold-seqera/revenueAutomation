/**
 * GTM-138: Quote trigger for exchange rate management
 * Sets exchange rates at creation and manages rate locking at approval
 * 
 * @author Alex Goldstein / Syl Architecture
 * @date September 2025
 */
trigger QuoteTrigger on Quote (before insert, after update) {
    QuoteProcessOrchestratorHandler.handleTrigger();
}