From Coq Require Import ssreflect ssrfun ssrbool.
Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Require Import Setoid.
From Coq Require Import Unicode.Utf8.
From Coq.Logic Require Import Classical_Prop FunctionalExtensionality.
From Coq.Classes Require Import Morphisms_Prop.

From stdpp Require Import base sets.

From MatchingLogic Require Import Syntax Semantics DerivedOperators Utils.extralibrary.
Require Import MatchingLogic.Theories.Definedness.

Import MatchingLogic.Syntax.Notations.
Import MatchingLogic.Syntax.BoundVarSugar.
Import MatchingLogic.Semantics.Notations.
Import MatchingLogic.IndexManipulation.
Import MatchingLogic.DerivedOperators.Notations.


Inductive Symbols := inhabitant.

Instance Symbols_eqdec : EqDecision Symbols.
Proof. unfold EqDecision. intros x y. unfold Decision. destruct x. decide equality. (*solve_decision.*) Defined.

Section sorts.

  Context {Σ : Signature}.

  Class Syntax :=
    { inj : Symbols -> symbols;
      imported_definedness :> Definedness.Syntax;
    }.

  Context {self : Syntax}.

  Local Definition sym (s : Symbols) : Pattern :=
    patt_sym (inj s).
  
  Example test_pattern_1 := patt_equal (sym inhabitant) (sym inhabitant).
  Definition patt_inhabitant_set(phi : Pattern) : Pattern := sym inhabitant $ phi.


  Lemma bevar_subst_inhabitant_set ψ (wfcψ : well_formed_closed ψ) x ϕ :
    bevar_subst (patt_inhabitant_set ϕ) ψ x = patt_inhabitant_set (bevar_subst ϕ ψ x).
  Proof. unfold patt_inhabitant_set. simpl_bevar_subst. reflexivity. Qed.
  
  Lemma bsvar_subst_inhabitant_set ψ (wfcψ : well_formed_closed ψ) x ϕ :
    bsvar_subst (patt_inhabitant_set ϕ) ψ x = patt_inhabitant_set (bsvar_subst ϕ ψ x).
  Proof. unfold patt_inhabitant_set. simpl_bsvar_subst. reflexivity. Qed.
  
  #[global]
   Instance Unary_inhabitant_set : Unary patt_inhabitant_set :=
    {| unary_bevar_subst := bevar_subst_inhabitant_set ;
       unary_bsvar_subst := bsvar_subst_inhabitant_set ;
    |}.

  Definition patt_forall_of_sort (sort phi : Pattern) : Pattern :=
    patt_forall ((patt_in (patt_bound_evar 0) (patt_inhabitant_set (nest_ex sort))) ---> phi).

  Definition patt_exists_of_sort (sort phi : Pattern) : Pattern :=
    patt_exists ((patt_in (patt_bound_evar 0) (patt_inhabitant_set (nest_ex sort))) and phi).

  Lemma bevar_subst_forall_of_sort s ψ (wfcψ : well_formed_closed ψ) db ϕ :
    bevar_subst (patt_forall_of_sort s ϕ) ψ db = patt_forall_of_sort (bevar_subst s ψ db) (bevar_subst ϕ ψ (S db)).
  Proof.
    unfold patt_forall_of_sort.
    repeat (rewrite simpl_bevar_subst';[assumption|]).
    simpl. unfold nest_ex. replace (S db) with (db + 1) by lia. rewrite nest_ex_gt; auto. lia.
  Qed.

  Lemma bsvar_subst_forall_of_sort s ψ (wfcψ : well_formed_closed ψ) db ϕ :
    bsvar_subst (patt_forall_of_sort s ϕ) ψ db = patt_forall_of_sort (bsvar_subst s ψ db) (bsvar_subst ϕ ψ db).
  Proof.
    unfold patt_forall_of_sort.
    repeat (rewrite simpl_bsvar_subst';[assumption|]).
    simpl.
    rewrite bsvar_subst_nest_ex_aux_comm.
    { unfold well_formed_closed in wfcψ. destruct_and!. assumption. }
    reflexivity.
  Qed.

  Lemma bevar_subst_exists_of_sort s ψ (wfcψ : well_formed_closed ψ) db ϕ :
    bevar_subst (patt_exists_of_sort s ϕ) ψ db = patt_exists_of_sort (bevar_subst s ψ db) (bevar_subst ϕ ψ (db+1)).
  Proof.
    unfold patt_exists_of_sort.
    repeat (rewrite simpl_bevar_subst';[assumption|]).
    (* TODO rewrite all _+1 to 1+_ *)
    rewrite PeanoNat.Nat.add_comm. simpl.
    unfold nest_ex.
    simpl. unfold nest_ex. replace (S db) with (db + 1) by lia. rewrite nest_ex_gt; auto. lia.
  Qed.

  Lemma bsvar_subst_exists_of_sort s ψ (wfcψ : well_formed_closed ψ) db ϕ :
    bsvar_subst (patt_exists_of_sort s ϕ) ψ db = patt_exists_of_sort (bsvar_subst s ψ db) (bsvar_subst ϕ ψ db).
  Proof.
    unfold patt_exists_of_sort.
    repeat (rewrite simpl_bsvar_subst';[assumption|]).
    simpl.
    rewrite bsvar_subst_nest_ex_aux_comm.
    { unfold well_formed_closed in wfcψ. destruct_and!. assumption. }
    reflexivity.
  Qed.
    
  #[global]
   Instance EBinder_forall_of_sort s : EBinder (patt_forall_of_sort s) _ _:=
    {|
    ebinder_bevar_subst := bevar_subst_forall_of_sort s ;
    ebinder_bsvar_subst := bsvar_subst_forall_of_sort s ;
    |}.

  #[global]
   Instance EBinder_exists_of_sort s : EBinder (patt_exists_of_sort s) _ _:=
    {|
    ebinder_bevar_subst := bevar_subst_exists_of_sort s ;
    ebinder_bsvar_subst := bsvar_subst_exists_of_sort s ;
    |}.
  
  (* TODO patt_forall_of_sort and patt_exists_of_sorts are duals - a lemma *)

  (* TODO a lemma about patt_forall_of_sort *)
  
  Definition patt_total_function(phi from to : Pattern) : Pattern :=
    patt_forall_of_sort from (patt_exists_of_sort (nest_ex to) (patt_equal (patt_app (nest_ex (nest_ex phi)) b1) b0)).

  Definition patt_partial_function(phi from to : Pattern) : Pattern :=
    patt_forall_of_sort from (patt_exists_of_sort (nest_ex to) (patt_subseteq (patt_app (nest_ex (nest_ex phi)) b1) b0)).


  (* Assuming `f` is a total function, says it is injective on given domain. Does not quite work for partial functions. *)
  Definition patt_total_function_injective f from : Pattern :=
    patt_forall_of_sort from (patt_forall_of_sort (nest_ex from) (patt_imp (patt_equal (patt_app (nest_ex (nest_ex f)) b1) (patt_app (nest_ex (nest_ex f)) b0)) (patt_equal b1 b0))).

  (* Assuming `f` is a partial function, says it is injective on given domain. Works for total functions, too. *)
  Definition patt_partial_function_injective f from : Pattern :=
    patt_forall_of_sort
      from
      (patt_forall_of_sort
         (nest_ex from)
         (patt_imp
            (patt_not (patt_equal (patt_app (nest_ex (nest_ex f)) b1) patt_bott ))
            (patt_imp (patt_equal (patt_app (nest_ex (nest_ex f)) b1) (patt_app (nest_ex (nest_ex f)) b0)) (patt_equal b1 b0)))).
  

  Section with_model.
    Context {M : Model}.
    Hypothesis M_satisfies_theory : M ⊨ᵀ Definedness.theory.

    Definition Mpatt_inhabitant_set m := app_ext (sym_interp M (inj inhabitant)) {[m]}.

    (* ϕ is expected to be a sort pattern *)
    Definition Minterp_inhabitant ϕ ρₑ ρₛ := @pattern_interpretation Σ M ρₑ ρₛ (patt_app (sym inhabitant) ϕ).
    
    Lemma pattern_interpretation_forall_of_sort_predicate s ϕ ρₑ ρₛ:
      let x := fresh_evar ϕ in
      M_predicate M (evar_open 0 x ϕ) ->
      pattern_interpretation ρₑ ρₛ (patt_forall_of_sort s ϕ) = ⊤
      <-> (∀ m : Domain M, m ∈ Minterp_inhabitant s ρₑ ρₛ ->
                           pattern_interpretation (update_evar_val x m ρₑ) ρₛ (evar_open 0 x ϕ) = ⊤).
    Proof.
      intros x Hpred.
      unfold patt_forall_of_sort.
      assert (Hsub: is_subformula_of_ind ϕ (patt_in b0 (patt_inhabitant_set (nest_ex s)) ---> ϕ)).
      { apply sub_imp_r. apply sub_eq. reflexivity.  }
      rewrite pattern_interpretation_forall_predicate.
      2: {
        unfold evar_open. simpl_bevar_subst. simpl.
        apply M_predicate_impl.
        - apply T_predicate_in.
          apply M_satisfies_theory.
        - subst x.
          apply M_predicate_evar_open_fresh_evar_2.
          2: apply Hpred.
          eapply evar_fresh_in_subformula. apply Hsub. apply set_evar_fresh_is_fresh.
      }
      subst x.
      remember (patt_in b0 (patt_inhabitant_set (nest_ex s)) ---> ϕ) as Bigϕ.
      assert (Hfresh: fresh_evar Bigϕ ∉ free_evars (patt_sym (inj inhabitant) $ (nest_ex s))).
      { rewrite HeqBigϕ.
        unfold patt_inhabitant_set.
        fold (evar_is_fresh_in (fresh_evar (patt_in b0 (sym inhabitant $ s) ---> ϕ)) (patt_sym (inj inhabitant) $ s)).
        unfold sym.
        eapply evar_fresh_in_subformula.
        2: apply set_evar_fresh_is_fresh.
        (* TODO automation *)
        apply sub_imp_l. unfold patt_in. unfold patt_defined.
        apply sub_app_r. unfold patt_and.
        unfold patt_not. unfold patt_or.
        apply sub_imp_l. apply sub_imp_r.
        apply sub_imp_l. apply sub_eq. reflexivity.
      }

      remember (patt_in b0 (patt_inhabitant_set s) ---> ϕ) as Bigϕ'.
      assert (HfreeBigϕ: free_evars Bigϕ = free_evars Bigϕ').
      { subst. simpl. unfold nest_ex. rewrite free_evars_nest_ex_aux. reflexivity. }
      assert (HfreshBigϕ: fresh_evar Bigϕ = fresh_evar Bigϕ').
      { unfold fresh_evar. rewrite HfreeBigϕ. reflexivity. }
      clear HfreeBigϕ.

      assert (Hfrs: evar_is_fresh_in (fresh_evar Bigϕ) s).
      { unfold evar_is_fresh_in.
        rewrite HfreshBigϕ. fold (evar_is_fresh_in (fresh_evar Bigϕ') s).
        eapply evar_fresh_in_subformula'. 2: apply set_evar_fresh_is_fresh.
        rewrite HeqBigϕ'. simpl. rewrite is_subformula_of_refl. simpl.
        rewrite !orb_true_r. auto.
      }
            
      split.
      - intros H m H'.
        specialize (H m).
        (*rewrite -interpretation_fresh_evar_subterm.*)
        rewrite -(@interpretation_fresh_evar_subterm _ _ _ Bigϕ).
        rewrite HeqBigϕ in H.
        rewrite evar_open_imp in H.
        rewrite -HeqBigϕ in H.
        assumption.
        rewrite {3}HeqBigϕ in H.
        eapply pattern_interpretation_impl_MP.
        apply H.
        simpl. fold evar_open.
  
        unfold Minterp_inhabitant in H'.
        pose proof (Hfeip := @free_evar_in_patt _ _ M M_satisfies_theory (fresh_evar Bigϕ) (patt_sym (inj inhabitant) $ evar_open 0 (fresh_evar Bigϕ) (nest_ex s)) (update_evar_val (fresh_evar Bigϕ) m ρₑ) ρₛ).
        destruct Hfeip as [Hfeip1 _]. apply Hfeip1. clear Hfeip1.
        rewrite update_evar_val_same.
        clear H. unfold sym in H'.
        unfold Ensembles.In.
        
        rewrite pattern_interpretation_app_simpl.
        unfold evar_open. rewrite nest_ex_same.
        rewrite pattern_interpretation_sym_simpl.

        rewrite pattern_interpretation_app_simpl in H'.
        rewrite pattern_interpretation_sym_simpl in H'.
        rewrite pattern_interpretation_free_evar_independent.
        {
          solve_free_evars_inclusion 5.
        }
        apply H'.

      - intros H m.
        pose proof (Hfeip := @free_evar_in_patt _ _ M M_satisfies_theory (fresh_evar Bigϕ) (patt_sym (inj inhabitant) $ evar_open 0 (fresh_evar Bigϕ) (nest_ex s)) (update_evar_val (fresh_evar Bigϕ) m ρₑ) ρₛ).
        destruct Hfeip as [_ Hfeip2].
        rewrite {3}HeqBigϕ.
        unfold evar_open. simpl_bevar_subst. simpl.
        apply pattern_interpretation_predicate_impl.
        apply T_predicate_in. apply M_satisfies_theory.
        intros H1.
        specialize (Hfeip2 H1). clear H1.
        specialize (H m).
        rewrite -(@interpretation_fresh_evar_subterm _ _ _ Bigϕ) in H.
        apply Hsub. apply H. clear H.

        unfold Minterp_inhabitant.
        unfold Ensembles.In in Hfeip2. unfold sym.


        rewrite pattern_interpretation_app_simpl in Hfeip2.
        unfold evar_open in Hfeip2. rewrite nest_ex_same in Hfeip2.
        rewrite pattern_interpretation_sym_simpl in Hfeip2.

        rewrite pattern_interpretation_app_simpl.
        rewrite pattern_interpretation_sym_simpl.
        rewrite update_evar_val_same in Hfeip2.
        rewrite pattern_interpretation_free_evar_independent in Hfeip2.
        {
          solve_free_evars_inclusion 5.
        }
        apply Hfeip2.
    Qed.

    Lemma pattern_interpretation_exists_of_sort_predicate s ϕ ρₑ ρₛ:
      let x := fresh_evar ϕ in
      M_predicate M (evar_open 0 x ϕ) ->
      pattern_interpretation ρₑ ρₛ (patt_exists_of_sort s ϕ) = ⊤
      <-> (∃ m : Domain M, m ∈ Minterp_inhabitant s ρₑ ρₛ /\
                           pattern_interpretation (update_evar_val x m ρₑ) ρₛ (evar_open 0 x ϕ) = ⊤).
    Proof.
      intros x Hpred.
      unfold patt_exists_of_sort.
      assert (Hsub: is_subformula_of_ind ϕ (patt_in b0 (patt_inhabitant_set (nest_ex s)) and ϕ)).
      { unfold patt_and. unfold patt_or.  apply sub_imp_l. apply sub_imp_r. apply sub_imp_l. apply sub_eq. reflexivity. }
      rewrite -> pattern_interpretation_exists_predicate_full.
      2: {
        unfold evar_open. simpl_bevar_subst. simpl.
        apply M_predicate_and.
        - apply T_predicate_in.
          apply M_satisfies_theory.
        - subst x.
          apply M_predicate_evar_open_fresh_evar_2.
          2: apply Hpred.
          eapply evar_fresh_in_subformula. apply Hsub. apply set_evar_fresh_is_fresh.
      }
      subst x.
      remember (patt_in b0 (patt_inhabitant_set (nest_ex s)) and ϕ) as Bigϕ.
      assert (Hfresh: fresh_evar Bigϕ ∉ free_evars (patt_sym (inj inhabitant) $ (nest_ex s))).
      { rewrite HeqBigϕ.
        unfold patt_inhabitant_set.
        fold (evar_is_fresh_in (fresh_evar (patt_in b0 (sym inhabitant $ s) and ϕ)) (patt_sym (inj inhabitant) $ s)).
        unfold sym.
        eapply evar_fresh_in_subformula.
        2: apply set_evar_fresh_is_fresh.
        (* TODO automation *)
        unfold patt_and. unfold patt_not. unfold patt_or.
        apply sub_imp_l. apply sub_imp_l. apply sub_imp_l.
        apply sub_imp_l. unfold patt_in. unfold patt_defined.
        apply sub_app_r. unfold patt_and.
        unfold patt_not. unfold patt_or.
        apply sub_imp_l. apply sub_imp_r.
        apply sub_imp_l. apply sub_eq. reflexivity.
      }

      remember (patt_in b0 (patt_inhabitant_set s) and ϕ) as Bigϕ'.
      assert (HfreeBigϕ: free_evars Bigϕ = free_evars Bigϕ').
      { subst. simpl. unfold nest_ex. rewrite free_evars_nest_ex_aux. reflexivity. }
      assert (HfreshBigϕ: fresh_evar Bigϕ = fresh_evar Bigϕ').
      { unfold fresh_evar. rewrite HfreeBigϕ. reflexivity. }
      clear HfreeBigϕ.

      assert (Hfrs: evar_is_fresh_in (fresh_evar Bigϕ) s).
      { unfold evar_is_fresh_in.
        rewrite HfreshBigϕ. fold (evar_is_fresh_in (fresh_evar Bigϕ') s).
        eapply evar_fresh_in_subformula'. 2: apply set_evar_fresh_is_fresh.
        rewrite HeqBigϕ'. simpl. rewrite is_subformula_of_refl. simpl.
        rewrite !orb_true_r. auto.
      }
      
      split.
      - intros [m H].
        exists m.
        rewrite -(@interpretation_fresh_evar_subterm _ _ _ Bigϕ).
        assumption.
        rewrite {3}HeqBigϕ in H.

        apply pattern_interpretation_and_full in H.
        fold evar_open in H.
        destruct H as [H1 H2].
        split. 2: apply H2. clear H2.
        unfold Minterp_inhabitant.
        pose proof (Hfeip := @free_evar_in_patt _ _ M M_satisfies_theory (fresh_evar Bigϕ) (patt_sym (inj inhabitant) $ evar_open 0 (fresh_evar Bigϕ) (nest_ex s)) (update_evar_val (fresh_evar Bigϕ) m ρₑ) ρₛ).
        destruct Hfeip as [_ Hfeip2].

        apply Hfeip2 in H1. clear Hfeip2.
        rewrite update_evar_val_same in H1.
        unfold sym.
        unfold Ensembles.In in H1.

        rewrite pattern_interpretation_app_simpl in H1.
        unfold evar_open in H1.
        rewrite nest_ex_same in H1.
        rewrite pattern_interpretation_sym_simpl in H1.

        rewrite pattern_interpretation_app_simpl.
        rewrite pattern_interpretation_sym_simpl.
        rewrite pattern_interpretation_free_evar_independent in H1.
        {
          solve_free_evars_inclusion 5.
        }
        apply H1.

      - intros [m [H1 H2] ]. exists m.
        pose proof (Hfeip := @free_evar_in_patt _ _ M M_satisfies_theory (fresh_evar Bigϕ) (patt_sym (inj inhabitant) $ evar_open 0 (fresh_evar Bigϕ) (nest_ex s)) (update_evar_val (fresh_evar Bigϕ) m ρₑ) ρₛ).
        destruct Hfeip as [Hfeip1 _].
        rewrite {3}HeqBigϕ.
        apply pattern_interpretation_and_full. fold evar_open.
        split.
        + apply Hfeip1. clear Hfeip1.
          unfold Ensembles.In.
          rewrite -> update_evar_val_same.
          unfold Minterp_inhabitant in H1. unfold sym in H1.

          rewrite pattern_interpretation_app_simpl in H1.
          rewrite pattern_interpretation_sym_simpl in H1.

          rewrite pattern_interpretation_app_simpl.
          unfold evar_open. rewrite nest_ex_same.
          rewrite pattern_interpretation_sym_simpl.
          rewrite pattern_interpretation_free_evar_independent.
          {
            solve_free_evars_inclusion 5.
          }
          apply H1.
        + rewrite -(@interpretation_fresh_evar_subterm _ _ _ Bigϕ) in H2.
          apply Hsub.
          apply H2.
    Qed.


    Lemma M_predicate_exists_of_sort s ϕ :
      let x := fresh_evar ϕ in
      M_predicate M (evar_open 0 x ϕ) -> M_predicate M (patt_exists_of_sort s ϕ).
    Proof.
      intros x Hpred.
      unfold patt_exists_of_sort.
      apply M_predicate_exists.
      unfold evar_open. simpl_bevar_subst.
      rewrite {1}[bevar_subst _ _ _]/=.
      apply M_predicate_and.
      - apply T_predicate_in.
        apply M_satisfies_theory.
      - subst x.
        apply M_predicate_evar_open_fresh_evar_2.
        2: apply Hpred.
        eapply evar_fresh_in_subformula.
        2: apply set_evar_fresh_is_fresh.
        unfold patt_and. unfold patt_not. unfold patt_or.
        apply sub_imp_l.
        apply sub_imp_r. apply sub_imp_l. apply sub_eq. reflexivity.
    Qed.

    Hint Resolve M_predicate_exists_of_sort : core.

    Lemma M_predicate_forall_of_sort s ϕ :
      let x := fresh_evar ϕ in
      M_predicate M (evar_open 0 x ϕ) -> M_predicate M (patt_forall_of_sort s ϕ).
    Proof.
      intros x Hpred.
      unfold patt_forall_of_sort.
      apply M_predicate_forall.
      unfold evar_open. simpl_bevar_subst.
      apply M_predicate_impl.
      - apply T_predicate_in.
        apply M_satisfies_theory.
      - subst x.
        apply M_predicate_evar_open_fresh_evar_2.
        2: apply Hpred.
        eapply evar_fresh_in_subformula. 2: apply set_evar_fresh_is_fresh.
        apply sub_imp_r. apply sub_eq. reflexivity.
    Qed.

    Hint Resolve M_predicate_forall_of_sort : core.

    Lemma interp_total_function f s₁ s₂ ρₑ ρₛ :
      @pattern_interpretation Σ M ρₑ ρₛ (patt_total_function f s₁ s₂) = ⊤ <->
      @is_total_function Σ M f (Minterp_inhabitant s₁ ρₑ ρₛ) (Minterp_inhabitant s₂ ρₑ ρₛ) ρₑ ρₛ.
    Proof.
      unfold is_total_function.
      rewrite pattern_interpretation_forall_of_sort_predicate.
      2: { eauto. }

      unfold evar_open. simpl_bevar_subst.
      remember (fresh_evar (patt_exists_of_sort (nest_ex s₂) (patt_equal ((nest_ex (nest_ex f)) $ b1) b0))) as x'.
      rewrite [nest_ex s₂]/nest_ex.
      unfold nest_ex. repeat rewrite nest_ex_same.
      rewrite fuse_nest_ex_same. rewrite nest_ex_same_general. 1-2: lia. simpl.
      rewrite -/(nest_ex s₂).

      apply all_iff_morphism.
      unfold pointwise_relation. intros m₁.
      apply all_iff_morphism. unfold pointwise_relation. intros Hinh1.

      rewrite pattern_interpretation_exists_of_sort_predicate.
      2: {
        unfold evar_open. simpl_bevar_subst.
        apply T_predicate_equals; apply M_satisfies_theory.
      }
      apply ex_iff_morphism. unfold pointwise_relation. intros m₂.

      unfold Minterp_inhabitant.
      rewrite 2!pattern_interpretation_app_simpl.
      rewrite 2!pattern_interpretation_sym_simpl.
      rewrite pattern_interpretation_free_evar_independent.
      (* two subgoals *)
      fold (evar_is_fresh_in x' (nest_ex s₂)).

      assert (Hfreq: x' = fresh_evar (patt_imp s₂ (nest_ex (nest_ex f)))).
      { rewrite Heqx'. unfold fresh_evar. apply f_equal. simpl.
        rewrite 2!free_evars_nest_ex_aux.
        rewrite !(left_id_L ∅ union). rewrite !(right_id_L ∅ union).
        rewrite (idemp_L union). reflexivity.
      }
      {
        rewrite Hfreq.
        unfold evar_is_fresh_in.
        eapply evar_is_fresh_in_richer'.
        2: apply set_evar_fresh_is_fresh'. solve_free_evars_inclusion 5.
      }

      apply and_iff_morphism; auto.

      unfold nest_ex.
      unfold evar_open. simpl_bevar_subst.
      repeat rewrite nest_ex_same.


      remember (fresh_evar (patt_equal (nest_ex_aux 0 1 f $ patt_free_evar x') b0)) as x''.

      rewrite equal_iff_interpr_same. 2: apply M_satisfies_theory.
      simpl. rewrite pattern_interpretation_free_evar_simpl.
      rewrite update_evar_val_same.
      rewrite pattern_interpretation_app_simpl.
      rewrite pattern_interpretation_free_evar_simpl.

      (*  Hx''neqx' : x'' ≠ x'
          Hx''freeinf : x'' ∉ free_evars f
       *)
      rewrite {2}update_evar_val_comm.
      {
        solve_fresh_neq.
      }
      rewrite update_evar_val_same.
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx''. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx'. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      auto.
    Qed.

    Lemma interp_partial_function f s₁ s₂ ρₑ ρₛ :
      @pattern_interpretation Σ M ρₑ ρₛ (patt_partial_function f s₁ s₂) = ⊤ <->
      ∀ (m₁ : Domain M),
        m₁ ∈ Minterp_inhabitant s₁ ρₑ ρₛ ->
        ∃ (m₂ : Domain M),
          m₂ ∈ Minterp_inhabitant s₂ ρₑ ρₛ /\
          (app_ext (@pattern_interpretation Σ M ρₑ ρₛ f) {[m₁]})
            ⊆ {[m₂]}.
    Proof.
      rewrite pattern_interpretation_forall_of_sort_predicate.
      2: { eauto. }

      unfold evar_open. simpl_bevar_subst.
      remember (fresh_evar (patt_exists_of_sort (nest_ex s₂) (patt_subseteq ((nest_ex (nest_ex f)) $ b1) b0))) as x'.
      rewrite [nest_ex s₂]/nest_ex.
      rewrite nest_ex_same.
      unfold nest_ex.
      rewrite fuse_nest_ex_same. rewrite nest_ex_same_general. 1-2: lia. simpl.

      apply all_iff_morphism.
      unfold pointwise_relation. intros m₁.
      apply all_iff_morphism. unfold pointwise_relation. intros Hinh1.

      rewrite pattern_interpretation_exists_of_sort_predicate.
      2: {
        unfold evar_open. simpl_bevar_subst.
        apply T_predicate_subseteq; apply M_satisfies_theory.
      }

      apply ex_iff_morphism. unfold pointwise_relation. intros m₂.

      unfold Minterp_inhabitant.
      rewrite 2!pattern_interpretation_app_simpl.
      rewrite 2!pattern_interpretation_sym_simpl.
      rewrite pattern_interpretation_free_evar_independent.
      {
        fold (evar_is_fresh_in x' (nest_ex s₂)).

        assert (Hfreq: x' = fresh_evar (patt_imp s₂ (nest_ex (nest_ex f)))).
        { rewrite Heqx'. unfold fresh_evar. apply f_equal. simpl.
          rewrite 2!free_evars_nest_ex_aux.
          rewrite !(left_id_L ∅ union). rewrite !(right_id_L ∅ union).
          reflexivity.
        }

        rewrite Hfreq.
        unfold nest_ex.
        unfold evar_is_fresh_in.
        eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }

      apply and_iff_morphism; auto.

      unfold evar_open. simpl_bevar_subst.
      rewrite nest_ex_same.
      simpl.
      remember (fresh_evar (patt_subseteq (nest_ex_aux 0 1 f $ patt_free_evar x') b0)) as x''.

      rewrite subseteq_iff_interpr_subseteq. 2: apply M_satisfies_theory.
      simpl. rewrite pattern_interpretation_free_evar_simpl.
      rewrite update_evar_val_same.
      rewrite pattern_interpretation_app_simpl.
      rewrite pattern_interpretation_free_evar_simpl.

      (*  Hx''neqx' : x'' ≠ x'
          Hx''freeinf : x'' ∉ free_evars f
       *)

      rewrite {2}update_evar_val_comm.
      {
        solve_fresh_neq.
      }
      rewrite update_evar_val_same.
      unfold nest_ex.

      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx''. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx'. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      auto.
    Qed.

    Lemma Minterp_inhabitant_evar_open_update_evar_val ρₑ ρₛ x e s m:
      evar_is_fresh_in x s ->
      m ∈ Minterp_inhabitant (evar_open 0 x (nest_ex s)) (update_evar_val x e ρₑ) ρₛ
      <-> m ∈ Minterp_inhabitant s ρₑ ρₛ.
    Proof.
      intros Hfr.
      unfold Minterp_inhabitant.
      rewrite 2!pattern_interpretation_app_simpl.
      rewrite 2!pattern_interpretation_sym_simpl.
      unfold nest_ex, evar_open. rewrite nest_ex_same.
      rewrite pattern_interpretation_free_evar_independent; auto.
   Qed.

    Lemma interp_partial_function_injective f s ρₑ ρₛ :
      @pattern_interpretation Σ M ρₑ ρₛ (patt_partial_function_injective f s) = ⊤ <->
      ∀ (m₁ : Domain M),
        m₁ ∈ Minterp_inhabitant s ρₑ ρₛ ->
        ∀ (m₂ : Domain M),
          m₂ ∈ Minterp_inhabitant s ρₑ ρₛ ->
          (rel_of ρₑ ρₛ f) m₁ ≠ ∅ ->
          (rel_of ρₑ ρₛ f) m₁ = (rel_of ρₑ ρₛ f) m₂ ->
          m₁ = m₂.
    Proof.
      unfold patt_partial_function_injective.
      rewrite pattern_interpretation_forall_of_sort_predicate.
      2: {
        match goal with
        | [ |- M_predicate _ (evar_open _ ?x _) ] => remember x
        end.
        unfold evar_open. simpl_bevar_subst. simpl.
        apply M_predicate_forall_of_sort.
        match goal with
        | [ |- M_predicate _ (evar_open _ ?x _) ] => remember x
        end.
        unfold evar_open. simpl_bevar_subst. simpl.
        eauto.
      }
      remember
      (fresh_evar
             (patt_forall_of_sort (nest_ex s)
                (! patt_equal (nest_ex (nest_ex f) $ b1) ⊥ --->
                 patt_equal (nest_ex (nest_ex f) $ b1) (nest_ex (nest_ex f) $ b0) --->
                 patt_equal b1 b0)))
      as x₁.
      apply all_iff_morphism. intros m₁.
      apply all_iff_morphism. intros Hm₁s.

      unfold evar_open. simpl_bevar_subst.
      rewrite pattern_interpretation_forall_of_sort_predicate. 2: { eauto 8. }
      remember
      (fresh_evar
             (! patt_equal
                  ((nest_ex (nest_ex f)).[evar:1↦patt_free_evar x₁] $ b1.[evar:1↦patt_free_evar x₁])
                  ⊥ --->
              patt_equal
                ((nest_ex (nest_ex f)).[evar:1↦patt_free_evar x₁] $ b1.[evar:1↦patt_free_evar x₁])
                ((nest_ex (nest_ex f)).[evar:1↦patt_free_evar x₁] $ b0.[evar:1↦patt_free_evar x₁]) --->
              patt_equal b1.[evar:1↦patt_free_evar x₁] b0.[evar:1↦patt_free_evar x₁]))
      as x₂.

      apply all_iff_morphism. intros m₂.
      rewrite Minterp_inhabitant_evar_open_update_evar_val.
      2: {
        eapply evar_is_fresh_in_richer.
        2: { subst x₁.
             apply set_evar_fresh_is_fresh.
        }
        solve_free_evars_inclusion 5.
      }
      apply all_iff_morphism. intros Hm₂s.
      unfold evar_open. simpl_bevar_subst.
      unfold nest_ex in *.
      rewrite fuse_nest_ex_same in Heqx₂, Heqx₁. rewrite nest_ex_same_general in Heqx₁, Heqx₂.
      1-2: lia.
      rewrite fuse_nest_ex_same. rewrite nest_ex_same_general. 1-2: lia. simpl.
      rewrite nest_ex_same.
      simpl in Heqx₁, Heqx₂.

      rewrite pattern_interpretation_predicate_impl. 2: { eauto. }
      simpl.
      rewrite pattern_interpretation_predicate_not. 2: { eauto. }
      rewrite equal_iff_interpr_same.
      rewrite pattern_interpretation_bott_simpl. 2: apply M_satisfies_theory.
      rewrite pattern_interpretation_app_simpl.
      rewrite pattern_interpretation_free_evar_simpl.
      rewrite update_evar_val_neq.
      { solve_fresh_neq. }
      rewrite update_evar_val_same.
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx₂. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx₁. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      fold (rel_of ρₑ ρₛ f m₁).
      apply all_iff_morphism. unfold pointwise_relation. intros Hnonempty.

      rewrite pattern_interpretation_predicate_impl. 2: { eauto. }
      (*rewrite simpl_evar_open.*)
      rewrite equal_iff_interpr_same. 2: apply M_satisfies_theory.
      rewrite 2!pattern_interpretation_app_simpl.
      rewrite equal_iff_interpr_same. 2: { apply M_satisfies_theory. }
      rewrite !pattern_interpretation_free_evar_simpl.
      rewrite update_evar_val_same.
      rewrite update_evar_val_neq.
      { solve_fresh_neq. }
      rewrite update_evar_val_same.
      unfold rel_of.
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx₂. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx₁. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      apply all_iff_morphism. intros Hfm1eqfm2.
      clear.
      set_solver.
    Qed.

    Lemma interp_total_function_injective f s ρₑ ρₛ :
      @pattern_interpretation Σ M ρₑ ρₛ (patt_total_function_injective f s) = ⊤ <->
      total_function_is_injective f (Minterp_inhabitant s ρₑ ρₛ) ρₑ ρₛ.
    Proof.
      unfold total_function_is_injective.
      unfold patt_partial_function_injective.
      rewrite pattern_interpretation_forall_of_sort_predicate.
      2: {
        match goal with
        | [ |- M_predicate _ (evar_open _ ?x _) ] => remember x
        end.
        unfold evar_open. simpl_bevar_subst. simpl.
        apply M_predicate_forall_of_sort.
        match goal with
        | [ |- M_predicate _ (evar_open _ ?x _) ] => remember x
        end.
        unfold evar_open. simpl_bevar_subst. simpl.
        eauto.
      }
      remember
      (fresh_evar
               (patt_forall_of_sort (nest_ex s)
                  (patt_equal (nest_ex (nest_ex f) $ b1) (nest_ex (nest_ex f) $ b0) ---> patt_equal b1 b0)))
      as x₁.
      apply all_iff_morphism. intros m₁.
      apply all_iff_morphism. intros Hm₁s.

      unfold evar_open. simpl_bevar_subst.
      rewrite pattern_interpretation_forall_of_sort_predicate.
      2: {
                match goal with
        | [ |- M_predicate _ (evar_open _ ?x _) ] => remember x
        end.
        unfold evar_open. simpl_bevar_subst. simpl.
        eauto.
      }
      remember
      (fresh_evar
             (patt_equal
                ((nest_ex (nest_ex f)).[evar:1↦patt_free_evar x₁] $ b1.[evar:1↦patt_free_evar x₁])
                ((nest_ex (nest_ex f)).[evar:1↦patt_free_evar x₁] $ b0.[evar:1↦patt_free_evar x₁]) --->
              patt_equal b1.[evar:1↦patt_free_evar x₁] b0.[evar:1↦patt_free_evar x₁]))
      as x₂.

      apply all_iff_morphism. intros m₂.
      rewrite Minterp_inhabitant_evar_open_update_evar_val.
      2: {
        eapply evar_is_fresh_in_richer.
        2: { subst. apply set_evar_fresh_is_fresh. }
        solve_free_evars_inclusion 5.
      }
      apply all_iff_morphism. intros Hm₂s.
      unfold nest_ex, evar_open in *.
      rewrite fuse_nest_ex_same in Heqx₂, Heqx₁. rewrite nest_ex_same_general in Heqx₁, Heqx₂.
      1-2: lia.
      rewrite fuse_nest_ex_same. rewrite nest_ex_same_general. 1-2: lia. simpl pred.
      simpl_bevar_subst.

      rewrite pattern_interpretation_predicate_impl. 2: { eauto. }
      simpl.
      
      rewrite equal_iff_interpr_same.
      2: { apply M_satisfies_theory. }
      rewrite 2!pattern_interpretation_app_simpl.
      rewrite pattern_interpretation_free_evar_simpl.
      rewrite update_evar_val_neq.
      { solve_fresh_neq. }
      rewrite update_evar_val_same.

      rewrite pattern_interpretation_free_evar_simpl.
      rewrite update_evar_val_same.
      rewrite nest_ex_same.
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx₂. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      rewrite pattern_interpretation_free_evar_independent.
      {
         rewrite Heqx₁. unfold evar_is_fresh_in.
         eapply evar_is_fresh_in_richer'.
         2: apply set_evar_fresh_is_fresh'. cbn.
         solve_free_evars_inclusion 5.
      }
      fold (rel_of ρₑ ρₛ f m₁). fold (rel_of ρₑ ρₛ f m₂).
      apply all_iff_morphism. intros Hfm1eqfm2.


      rewrite equal_iff_interpr_same. 2: apply M_satisfies_theory.
      rewrite 2!pattern_interpretation_free_evar_simpl.
      rewrite update_evar_val_same.
      rewrite update_evar_val_neq.
      { solve_fresh_neq. }
      rewrite update_evar_val_same.
      clear. set_solver.
    Qed.


  End with_model.
    
End sorts.

    #[export]
    Hint Resolve M_predicate_exists_of_sort : core.

        #[export]
    Hint Resolve M_predicate_forall_of_sort : core.
